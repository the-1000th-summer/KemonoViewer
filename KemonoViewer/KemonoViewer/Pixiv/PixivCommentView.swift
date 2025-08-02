//
//  PixivCommentView.swift
//  KemonoViewer
//
//  Created on 2025/7/31.
//

import SwiftUI
import Kingfisher

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

struct PixivCommentRowWithReply: View {
    let comment: PixivComment
    
    @State private var showReplies = false
    
    var body: some View {
        VStack(alignment: .leading) {
            PixivCommentRow(comment: comment)
            if comment.hasReplies {
                if showReplies {
                    PixivReplyView(commentId: comment.id)
                        .padding(.leading, 60)
                } else {
                    LoadMoreCommentsButton(buttonStr: "查看回复") {
                        showReplies = true
                    }
                    .padding(.leading, 60)
                }
            }
        }
        .onAppear {
            showReplies = false
        }
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
                    .pointingHandCursor()
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
