//
//  CommentViewModel.swift
//  KemonoViewer
//
//  Created on 2025/7/31.
//

import Foundation
import SwiftyJSON

struct PixivComment: Identifiable {
    let id = UUID()
    let name: String
    let content: String
    let stampId: String?
//    let date: Date
}

class CommentViewModel: ObservableObject {
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
        // 确保在主线程更新状态
        await MainActor.run {
            guard !isLoading && canLoadMore else { return }
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let url = URL(string: "https://www.pixiv.net/ajax/illusts/comments/roots?illust_id=\(pixivPostId)&offset=\((currentPage-1)*pageSize)&limit=\(pageSize)")!

            let (fetcheddata, _) = try await URLSession.shared.data(from: url)
            
            let jsonObj = try JSON(data: fetcheddata)
            
            let newComments = jsonObj["body"]["comments"].map {
                PixivComment(
                    name: $0.1["userName"].stringValue,
                    content: $0.1["comment"].stringValue,
                    stampId: $0.1["stampId"].string
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
