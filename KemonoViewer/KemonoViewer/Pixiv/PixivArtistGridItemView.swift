//
//  PixivArtistGridItemView.swift
//  KemonoViewer
//
//  Created on 2025/7/24.
//

import SwiftUI
import Kingfisher

struct PixivArtistGridItemView: View {
    let artistData: PixivArtist_show
    let size: CGSize
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .leading) {
                
                KFImage(findFileURL(fileNameWithoutExt: "background"))
                    .resizable()
                    .overlay(
                        LinearGradient(colors: [
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.8),
                        ], startPoint: .top, endPoint: .bottom)
                    )
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                HStack {
                    KFImage(findFileURL(fileNameWithoutExt: "avatar"))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80.0, height: 80.0)
                        .clipShape(Circle())
                        .padding(.leading, 25)
                        .padding(.trailing, 10)
                    VStack(alignment: .leading) {
//                        Text(ServiceTitleColor(rawValue: artistData.service)?.title ?? "Unknown")
//                            .font(.system(size: 15))
//                            .fontWeight(.bold)
//                            .padding(4)
//                            .background(
//                                RoundedRectangle(cornerRadius: 5)
//                                    .fill(ServiceTitleColor(rawValue: artistData.service)?.color ?? .black)
//                            )
                        
                        Text(artistData.name)
                            .font(.system(size: 25))
                            .fontWeight(.light)
                    }
                }
            }
        }
    }
    
    private func findFileURL(fileNameWithoutExt: String) -> URL? {
        let fileManager = FileManager.default
        let directoryURL = URL(filePath: Constants.pixivBaseDir).appendingPathComponent(artistData.folderName)
        
        do {
            // 获取目录下所有文件URL
            let fileURLs = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            let filesOnlyURLs = fileURLs.filter { !$0.hasDirectoryPath }
            let targetFilesURL = filesOnlyURLs.filter { $0.deletingPathExtension().lastPathComponent == fileNameWithoutExt }
            
            if targetFilesURL.isEmpty {
                return nil
            } else {
                if targetFilesURL.count > 1 {
                    print("warning: multiple avatar files, get first file as avatar.")
                }
                return targetFilesURL[0]
            }
        } catch {
            print("Error reading directory: \(error)")
            return nil
        }
    }
}

//#Preview {
//    PixivArtistGridItemView()
//}
