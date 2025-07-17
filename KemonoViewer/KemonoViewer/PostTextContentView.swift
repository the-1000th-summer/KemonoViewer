//
//  PostTextContentView.swift
//  KemonoViewer
//
//  Created on 2025/7/16.
//

import SwiftUI
import SwiftyJSON
import Kingfisher

struct PostTextContentView: View {
    
    @State private var contentStr = ""
    @State private var comments: [KemonoComment]?
    @ObservedObject var imagePointer: ImagePointer
    
    @State private var contentStrLoading = false
    @State private var isLoadingComments = false
    
    @ViewBuilder
    private func headerView() -> some View {
        if contentStrLoading {
            HStack{
                Spacer()
                ProgressView()
                Spacer()
            }
        } else {
            VStack(alignment: .leading) {
                HStack {
                    KFImage(URL(string: "https://img.kemono.su/icons/\(imagePointer.getArtistService())/\(imagePointer.getArtistKemonoId())"))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    Text(imagePointer.getArtistName())
                        .font(.system(size: 15))
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
                
                contentView()
                    .padding(.horizontal)
                Text(imagePointer.getCurrentPostDatetime())
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
                    .padding(.top, 1)
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        if let htmlData = contentStr.data(using: .utf16), let nsAttributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil),
           let attributedString = try? AttributedString(nsAttributedString, including: \.appKit) {
            Text(attributedString)
        } else {
            Text(contentStr)
        }
    }
    
    @ViewBuilder
    private func commentView() -> some View {
        if isLoadingComments {
            HStack{
                Spacer()
                ProgressView()
                Spacer()
            }
        } else {
            if let comments {
                if comments.isEmpty {
                    Text("No comments.")
                } else {
                    ForEach(comments, id: \.self) { comment in
                        PostCommentView(comment: comment)
                    }
                    Divider()
                }
            } else {
                Text("Comment load failed.")
                    .padding(.horizontal)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                headerView()
                commentView()
            }
            .onAppear {
                loadAllData()
            }
            .onChange(of: imagePointer.currentPostDirURL) {
                loadAllData()
            }
        }
    }
    
    private func loadAllData() {
        contentStrLoading = true
        isLoadingComments = true

        Task.detached {
            let loadedData = await loadContent()
            await MainActor.run {
                contentStr = loadedData
                contentStrLoading = false
            }
        }
        
        Task.detached {
            let loadedComments = await loadComments()
            await MainActor.run {
                comments = loadedComments
                isLoadingComments = false
            }
        }
    }
    
    private func loadContent() async -> String {
        guard let contentTxtFilePath = imagePointer.currentPostDirURL?.appendingPathComponent("content.txt") else { return "" }
        do {
            let originalStr = try String(contentsOf: contentTxtFilePath, encoding: .utf8)
            return String(format:"<span style=\"font-family: '-apple-system', 'HelveticaNeue'; font-size: 15\">%@</span>", originalStr)
        } catch {
            print(error.localizedDescription)
        }
        return ""
    }
    
    private func loadComments() async -> [KemonoComment]? {
        guard let kemonoPostId = imagePointer.getCurrentPostKemonoId() else { return nil }
        guard let apiUrl = URL(string: "https://kemono.su/api/v1/\(imagePointer.getArtistService())/user/\(imagePointer.getArtistKemonoId())/post/\(kemonoPostId)/comments") else { return nil }
        do {
            let fetcheddata = try await DataWriter.fetchData(from: apiUrl)
            
//            let (data, response) = try await URLSession.shared.data(from: apiUrl)
//            guard let httpResponse = response as? HTTPURLResponse,
//                  (200...299).contains(httpResponse.statusCode) else {
//                throw URLError(.badServerResponse)
//            }
//            return data
            
            guard let jsonObj = try? JSON(data: fetcheddata) else {
                print("转换为Json对象失败")
                return nil
            }
            let a = jsonObj.map {
                return KemonoComment(commenterName: $0.1["commenter_name"].string, commentContent: $0.1["content"].stringValue, publishedDatetimeStr: $0.1["published"].stringValue)
            }
            return a
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
}

struct KemonoComment: Hashable {
    let commenterName: String?
    let commentContent: String
    let publishedDatetime: Date?
    
    private static let commentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    init(commenterName: String?, commentContent: String, publishedDatetimeStr: String) {
        self.commenterName = commenterName
        self.commentContent = commentContent
        self.publishedDatetime = KemonoComment.commentDateFormatter.date(from: publishedDatetimeStr)
    }
}

//#Preview {
//    PostTextContentView()
//}
