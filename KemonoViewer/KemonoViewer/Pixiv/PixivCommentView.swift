//
//  PixivCommentView.swift
//  KemonoViewer
//
//  Created on 2025/7/31.
//

import SwiftUI
import Kingfisher
import SwiftyJSON

struct PixivCommentView: View {
    @StateObject private var viewModel = PixivCommentViewModel()
    
    let pixivPostId: String
    
    var body: some View {
        LazyVStack(alignment: .leading) {
            ForEach(viewModel.comments) { comment in
                PixivCommentRowWithReply(comment: comment)
                    .padding(.top, 20)
                    .onAppear {
                        // when about to reach bottom, load more comments
                        if shouldLoadMore(currentItem: comment) {
                            Task {
                                await viewModel.loadMoreComments(pixivPostId: pixivPostId)
                            }
                        }
                    }
            }
            if viewModel.isLoading {
                ProgressView()
            }
            if !viewModel.canLoadMore && !viewModel.comments.isEmpty {
                Text("没有更多评论了")
                    .foregroundColor(.secondary)
            }
        }
        .task {
            if viewModel.comments.isEmpty {
                await viewModel.loadMoreComments(pixivPostId: pixivPostId)
            }
        }
    }
    
    private func shouldLoadMore(currentItem: PixivComment) -> Bool {
        guard !viewModel.isLoading && viewModel.canLoadMore else { return false }
        
        // 当滚动到列表最后3个元素时触发加载
        guard let lastIndex = viewModel.comments.last?.id,
              let currentIndex = viewModel.comments.firstIndex(where: { $0.id == currentItem.id }) else {
            return false
        }
        
        let thresholdIndex = viewModel.comments.index(viewModel.comments.endIndex, offsetBy: -3)
        return currentIndex >= thresholdIndex && currentItem.id == lastIndex
    }
}

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
//            let (fetcheddata, _) = try await URLSession.shared.data(from: url)
            let url = URL(string: "https://www.pixiv.net/ajax/illusts/comments/replies?comment_id=\(commentId)&page=\(page)")!
            let request = URLRequest(url: url)
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

struct PixivCommentRowWithReply: View {
    let comment: PixivComment
    
    @State private var showReplies = false
    
    var body: some View {
        VStack(alignment: .leading) {
            PixivCommentRow(comment: comment)
            if comment.hasReplies {
                if showReplies {
                    PixivReplyView(commentId: comment.id)
                } else {
                    LoadMoreCommentsButton(buttonStr: "查看回复") {
                        showReplies = true
                    }
                }
            }
        }
        .onAppear {
            showReplies = false
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

struct PixivCommentRow: View {
    let comment: PixivComment
    
    var body: some View {
        HStack(alignment: .top) {
            Link(destination: URL(string: "https://www.pixiv.net/users/\(comment.userId)")!){
                KFImage(comment.avatar)
                    .cacheMemoryOnly(true)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .onHover { isHovering in
                        if isHovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 12)
            
            VStack(alignment: .leading) {
                if !comment.name.isEmpty {
                    Text(comment.name)
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                        .padding(.bottom, 3)
                }
                if let stampId = comment.stampId {
                    Image("\(stampId)_s")
                        .cornerRadius(5)
                } else {
                    PixivEmojiTextView(content: comment.content)
                        .fontWeight(.regular)
                        .font(.system(size: 15))
                        .padding(.bottom, 3)
                }
                Text(comment.date)
                    .foregroundStyle(.gray)
                    .font(.system(size: 15))
                
            }
        }
        
    }
}

//#Preview {
//    PixivCommentView()
//}
