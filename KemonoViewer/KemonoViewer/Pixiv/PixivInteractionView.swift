//
//  PixivInteractionView.swift
//  KemonoViewer
//
//  Created on 2025/8/3.
//

import SwiftUI

struct PixivInteractionView: View {
    
    @State private var likeCount: Int
    @State private var bookmarkCount: Int
    @State private var viewCount: Int
    @State private var commentCount: Int
    
    let postId: Int64
    
    init(postId: Int64, pixivContent: PixivContent_show) {
        self.postId = postId
        likeCount = pixivContent.likeCount
        bookmarkCount = pixivContent.bookmarkCount
        viewCount = pixivContent.viewCount
        commentCount = pixivContent.commentCount
    }
    
    private let interactionUpdatedPub = NotificationCenter.default.publisher(for: .pixivInteractionUpdated)
    
    var body: some View {
        HStack {
            PixivCountView(systemImageName: "face.smiling", countNumber: likeCount)
            PixivCountView(systemImageName: "heart.fill", countNumber: bookmarkCount)
            PixivCountView(systemImageName: "eye.fill", countNumber: viewCount)
            PixivCountView(systemImageName: "message.fill", countNumber: commentCount)
        }
        .padding(.vertical, 5)
        .onReceive(interactionUpdatedPub) { notification in
            guard let lc = notification.userInfo?["likeCount"] as? Int, let bc = notification.userInfo?["bookmarkCount"] as? Int, let vc = notification.userInfo?["viewCount"] as? Int, let cc = notification.userInfo?["commentCount"] as? Int else { return }
            
            if (likeCount != lc) || (bookmarkCount != bc) || (viewCount != vc) || (commentCount != cc) {
                likeCount = lc
                bookmarkCount = bc
                viewCount = vc
                commentCount = cc
                
                Task {
                    await PixivDataWriter.updateInteractionData(
                        postId: postId,
                        likeCount: likeCount,
                        bookmarkCount: bookmarkCount,
                        viewCount: viewCount,
                        commentCount: commentCount
                    )
                }
            }
        }
    }
}

//#Preview {
//    PixivInteractionView()
//}
