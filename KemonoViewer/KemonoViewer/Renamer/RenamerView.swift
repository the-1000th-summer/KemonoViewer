//
//  RenamerView.swift
//  KemonoViewer
//
//  Created on 2025/7/14.
//

import SwiftUI
import SwiftyJSON

struct RenamerView: View {
    @State private var pathBeforeRename = ""
    @State private var pathAfterRename = ""
    
    @State private var isProcessing = false
    @State private var readingProgress: Double = 0.0
    
    @State private var currentTask: Task<Void, Never>?
    
    var body: some View {
        VStack {
            HStack {
                Text(pathBeforeRename)
                    .onAppear {
                        pathBeforeRename = getPathBeforeRename()
                    }
                Image(systemName: "arrow.right.circle.fill")
                Text(pathAfterRename)
                    .onAppear {
                        pathAfterRename = getPathAfterRename()
                    }
            }
            Button("Rename all") {
                isProcessing = true
                readingProgress = 0.0
                currentTask = Task {
                    await renameAll(isProcessing: $isProcessing, progress: $readingProgress)
                }
                isProcessing = false
            }
        }
        .sheet(isPresented: $isProcessing) {
            VStack {
                ProgressView("Processing...", value: readingProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                    .interactiveDismissDisabled()
                Button("Cancel") {
                    currentTask?.cancel()
                    currentTask = nil
                }
            }
            
        }
        
    }
    
    private func renameAll(isProcessing: SwiftUI.Binding<Bool>, progress: SwiftUI.Binding<Double>) async {
        
//        await MainActor.run {
//            isProcessing.wrappedValue = true
//            progress.wrappedValue = 0.0
//        }
        
        
        
        guard let artistsName = getSubdirectoryNames(atPath: Constants.kemonoBaseDir) else { return }
        for (i, artistName) in artistsName.enumerated() {
            let artistDirURL = URL(filePath: Constants.kemonoBaseDir).appendingPathComponent(artistName)
            guard let postsName = getSubdirectoryNames(atURL: artistDirURL) else { return }
            let fm = FileManager.default
            for postName in postsName {
//                try Task.checkCancellation()
                
                let postUrlBeforeRename = artistDirURL.appendingPathComponent(postName)
                let jsonFileURL = postUrlBeforeRename.appendingPathComponent("post.json")
                guard let jsonFileData = try? Data(contentsOf: jsonFileURL) else {
                    print("打开Json文件失败")
                    return
                }
                
                guard let jsonObj = try? JSON(data: jsonFileData) else {
                    print("转换为Json对象失败")
                    return
                }
                
                let service = jsonObj["service"].stringValue
                let published = String(jsonObj["published"].stringValue.split(separator: "T")[0])
                let title = jsonObj["title"].stringValue
                
                let postNameAfterRename = "[\(service)][\(published)]\(title)"
                let postUrlAfterRename = artistDirURL.appendingPathComponent(postNameAfterRename)
                
                do {
                    try fm.moveItem(atPath: postUrlBeforeRename.path(percentEncoded: false), toPath: postUrlAfterRename.path(percentEncoded: false))
//                    try fm.moveItem(at: postUrlBeforeRename, to: postUrlAfterRename)
                } catch {
                    print(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                progress.wrappedValue = Double(i) / Double(artistsName.count)
            }
        }
        
        await MainActor.run {
            isProcessing.wrappedValue = false
        }
    }
    
    private func getPathBeforeRename() -> String {
        guard let firstArtistName = getSubdirectoryNames(atPath: Constants.kemonoBaseDir)?.first else { return "" }
        let firstArtistDirURL = URL(filePath: Constants.kemonoBaseDir).appendingPathComponent(firstArtistName)
        guard let firstPostName = getSubdirectoryNames(atURL: firstArtistDirURL)?.first else { return "" }
        
        return "\(firstArtistName) / \(firstPostName)"
    }
    
    private func getPathAfterRename() -> String {
        guard let firstArtistName = getSubdirectoryNames(atPath: Constants.kemonoBaseDir)?.first else { return "" }
        let firstArtistDirURL = URL(filePath: Constants.kemonoBaseDir).appendingPathComponent(firstArtistName)
        guard let firstPostName = getSubdirectoryNames(atURL: firstArtistDirURL)?.first else { return "" }
        let firstPostJsonFileURL = firstArtistDirURL.appendingPathComponent(firstPostName).appendingPathComponent("post.json")
        
        guard let jsonFileData = try? Data(contentsOf: firstPostJsonFileURL) else {
            print("打开Json文件失败")
            return ""
        }
        guard let jsonObj = try? JSON(data: jsonFileData) else {
            print("转换为Json对象失败")
            return ""
        }
        
        let service = jsonObj["service"].stringValue
        let published = String(jsonObj["published"].stringValue.split(separator: "T")[0])
        let title = jsonObj["title"].stringValue
        return "[\(service)][\(published)]\(title)"
    }
}

#Preview {
    RenamerView()
}
