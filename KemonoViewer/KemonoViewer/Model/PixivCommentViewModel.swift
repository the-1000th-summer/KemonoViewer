//
//  CommentViewModel.swift
//  KemonoViewer
//
//  Created on 2025/7/31.
//

import Foundation
import SwiftyJSON

struct PixivComment: Identifiable {
    let id: String
    let userId: String
    let name: String
    let avatar: URL
    let content: String
    let stampId: String?
    let date: String
    let hasReplies: Bool
}

class PixivCommentViewModel: ObservableObject {
    @Published var comments: [PixivComment] = []
    @Published var isLoading = false
    @Published var canLoadMore = true
    @Published var errorMessage: String?
    
    private var currentPage = 1
    private let pageSize = 20  // 每页加载数量
    
    func loadInitialData(pixivPostId: String) {
        guard !isLoading else { return }
        currentPage = 1
        canLoadMore = true
        Task {
            await loadMoreComments(pixivPostId: pixivPostId)
        }
    }

    func loadMoreComments(pixivPostId: String) async {
        await MainActor.run {
            guard !isLoading && canLoadMore else { return }
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let url = URL(string: "https://www.pixiv.net/ajax/illusts/comments/roots?illust_id=\(pixivPostId)&offset=\((currentPage-1)*pageSize)&limit=\(pageSize)")!
            var request = URLRequest(url: url)
            UtilFunc.configureBrowserHeaders(for: &request)

            let (fetcheddata, _) = try await URLSession.shared.data(for: request)
            
            let jsonObj = try JSON(data: fetcheddata)
            
            let newComments = jsonObj["body"]["comments"].map {
                PixivComment(
                    id: $0.1["id"].stringValue,
                    userId: $0.1["userId"].stringValue,
                    name: $0.1["userName"].stringValue,
                    avatar: URL(string: $0.1["img"].stringValue.replacingOccurrences(of: "i.pximg.net", with: "i.pixiv.re"))!,
                    content: $0.1["comment"].stringValue,
                    stampId: $0.1["stampId"].string,
                    date: $0.1["commentDate"].stringValue,
                    hasReplies: $0.1["hasReplies"].boolValue
                )
            }
            
            // 在主线程更新状态和数据
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                if self.currentPage == 1 {
                    self.comments = newComments
                } else {
                    self.comments.append(contentsOf: newComments)
                }
                
                // 检查是否还有更多数据
                self.canLoadMore = jsonObj["body"]["hasNext"].boolValue
                self.currentPage += 1
                self.isLoading = false
            }
        } catch {
            // 错误处理
            await MainActor.run { [weak self] in
                self?.isLoading = false
                self?.errorMessage = "加载失败: \(error.localizedDescription)"
            }
        }
    }
    
    
}
