//
//  PixivReplyView.swift
//  KemonoViewer
//
//  Created on 2025/8/1.
//

import SwiftUI
import SwiftyJSON

struct PixivReplyView: View {
    @State private var isLoadingReplies = false
    @State private var replies = [PixivComment]()
    @State private var currentPage = 1
    @State private var canLoadMore = false
    @State private var errorMessage: String? = nil
    
    let commentId: String
    
    var body: some View {
        VStack {
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)
            } else {
                ForEach(replies) { reply in
                    PixivCommentRow(comment: reply)
                }
                if isLoadingReplies {
                    ProgressView()
                } else {
                    if canLoadMore {
                        LoadMoreCommentsButton(buttonStr: "查看更多回复") {
                            Task {
                                await loadReplies(page: currentPage)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadReplies(page: currentPage)
            }
        }
    }
    
    private func loadReplies(page: Int) async {
        await MainActor.run {
            isLoadingReplies = true
        }
        
        do {

            let url = URL(string: "https://www.pixiv.net/ajax/illusts/comments/replies?comment_id=\(commentId)&page=\(page)")!
            var request = URLRequest(url: url)
            UtilFunc.configureBrowserHeaders(for: &request)
//            request.setValue("PHPSESSID=YOURCOOKIE", forHTTPHeaderField: "Cookie")
            
            let (fetcheddata, _) = try await URLSession.shared.data(for: request)
            let jsonObj = try JSON(data: fetcheddata)
            
            if jsonObj["error"].boolValue {
                await MainActor.run {
                    canLoadMore = false
                    errorMessage = jsonObj["message"].stringValue
                    isLoadingReplies = false
                }
            } else {
                let newReplies = jsonObj["body"]["comments"].map {
                    PixivComment(
                        id: $0.1["id"].stringValue,
                        userId: $0.1["userId"].stringValue,
                        name: $0.1["userName"].stringValue,
                        avatar: URL(string: $0.1["img"].stringValue.replacingOccurrences(of: "i.pximg.net", with: "i.pixiv.re"))!,
                        content: $0.1["comment"].stringValue,
                        stampId: $0.1["stampId"].string,
                        date: $0.1["commentDate"].stringValue,
                        hasReplies: false
                    )
                }
                
                await MainActor.run {
                    if currentPage == 1 {
                        replies = newReplies
                    } else {
                        replies.append(contentsOf: newReplies)
                    }
                    
                    canLoadMore = jsonObj["body"]["hasNext"].boolValue
                    currentPage += 1
                    isLoadingReplies = false
                }
                
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct LoadMoreCommentsButton: View {
    let buttonStr: String
    let buttonAction: () -> Void
    
    var body: some View {
        Button(action: buttonAction) {
            Text(buttonStr)
                .font(.system(size: 15))
                .fontWeight(.medium)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    Capsule()
                        .fill(Color(red: 56.0/255.0, green: 56.0/255.0, blue: 56.0/255.0))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
