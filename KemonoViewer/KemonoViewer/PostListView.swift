//
//  PostListView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct PostListView: View {
    @Binding var postsData: [Post_show]
    
    @Binding var postSelectedIndex: Int?
    var artistSelectedId: Int64?
    var queryConfig: QueryConfig
    
    private let pub = NotificationCenter.default.publisher(for: .updateNewViewedPostData)
    private let viewedPub = NotificationCenter.default.publisher(for: .updateAllPostViewedStatus)
    
    var body: some View {
        List(postsData.indices, id: \.self, selection: $postSelectedIndex) { postCurrentIndex in
            HStack {
                Image(systemName: "circlebadge.fill")
                    .foregroundStyle(.blue)
                    .opacity(postsData[postCurrentIndex].viewed ? 0 : 1)
                Text(postsData[postCurrentIndex].name)
            }
            .contextMenu {
                Button("标记为未读") {
                    newViewedStatusPost(postIndex: postCurrentIndex, viewed: false)
                }
            }
        }
        .onChange(of: postSelectedIndex) {
            if let postSelectedIndex {
                newViewedStatusPost(postIndex: postSelectedIndex, viewed: true)
            }
        }
        .onReceive(pub) { notification in
            guard let viewedPostIndex = notification.userInfo?["viewedPostIndex"] as? Int else { return }
            newViewedStatusPost(postIndex: viewedPostIndex, viewed: true)
        }
        .onReceive(viewedPub) { notification in
            refreshPostsData()
        }
    }
    
    private func refreshPostsData() {
        if let artistSelectedId {
            postsData = DataReader.readPostData(artistId: artistSelectedId, queryConfig: queryConfig) ?? []
        } else {
            postsData.removeAll()
        }
    }
    
    private func newViewedStatusPost(postIndex: Int, viewed: Bool) {
        let originalPostData = postsData[postIndex]
        postsData[postIndex] = Post_show(
            name: originalPostData.name,
            folderName: originalPostData.folderName,
            coverName: originalPostData.coverName,
            id: originalPostData.id,
            attNumber: originalPostData.attNumber,
            postDate: originalPostData.postDate,
            viewed: viewed
        )
        DatabaseManager.shared.tagPost(postId: postsData[postIndex].id, viewed: viewed)
    }
    
}

//#Preview {
//    PostListView(postSelectedId: .constant(0), artistSelectedId: 0)
//}
