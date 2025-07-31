//
//  PixivCommentView.swift
//  KemonoViewer
//
//  Created on 2025/7/31.
//

import SwiftUI
import Kingfisher

struct PixivCommentView: View {
    @StateObject private var viewModel = CommentViewModel()
    
    let pixivPostId: String
    
    var body: some View {
        LazyVStack(alignment: .leading) {
            ForEach(viewModel.comments) { comment in
                PixivCommentRow(comment: comment)
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

struct PixivCommentRow: View {
    let comment: PixivComment
    
    var body: some View {
        VStack(alignment: .leading) {
            if !comment.name.isEmpty {
                Text(comment.name)
            }
            if let stampId = comment.stampId {
                Image("\(stampId)_s")
            } else {
                PixivEmojiTextView(content: comment.content)
            }
        }
    }
}

//#Preview {
//    PixivCommentView()
//}
