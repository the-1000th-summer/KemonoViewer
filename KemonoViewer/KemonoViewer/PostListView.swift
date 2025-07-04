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
    var onlyShowNotViewedPost: Bool
    
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
                    newNotViewedPost(notViewedPostIndex: postCurrentIndex)
                }
            }
        }
        .onChange(of: artistSelectedId) {
            refreshPostsData()
        }
        .onChange(of: onlyShowNotViewedPost) {
            refreshPostsData()
            postSelectedIndex = nil
        }
        .onChange(of: postSelectedIndex) {
            if let postSelectedIndex {
                newViewedPost(viewedPostIndex: postSelectedIndex)
            }
        }
        .onReceive(pub) { notification in
            guard let viewedPostIndex = notification.userInfo?["viewedPostIndex"] as? Int else { return }
            newViewedPost(viewedPostIndex: viewedPostIndex)
        }
        .onReceive(viewedPub) { notification in
            refreshPostsData()
        }
    }
    
    private func refreshPostsData() {
        if let artistSelectedId {
            postsData = DataReader.readPostData(artistId: artistSelectedId, notViewedToggleisOn: onlyShowNotViewedPost) ?? []
        } else {
            postsData.removeAll()
        }
    }
    
    private func newViewedPost(viewedPostIndex: Int) {
        let originalPostData = postsData[viewedPostIndex]
        postsData[viewedPostIndex] = Post_show(
            name: originalPostData.name,
            folderName: originalPostData.folderName,
            coverName: originalPostData.coverName,
            id: originalPostData.id,
            attNumber: originalPostData.attNumber,
            postDate: originalPostData.postDate,
            viewed: true
        )
        DatabaseManager.shared.tagPost(postId: postsData[viewedPostIndex].id, viewed: true)
    }
    
    private func newNotViewedPost(notViewedPostIndex: Int) {
        let originalPostData = postsData[notViewedPostIndex]
        postsData[notViewedPostIndex] = Post_show(
            name: originalPostData.name,
            folderName: originalPostData.folderName,
            coverName: originalPostData.coverName,
            id: originalPostData.id,
            attNumber: originalPostData.attNumber,
            postDate: originalPostData.postDate,
            viewed: false
        )
        DatabaseManager.shared.tagPost(postId: postsData[notViewedPostIndex].id, viewed: false)
    }
    
}

//#Preview {
//    PostListView(postSelectedId: .constant(0), artistSelectedId: 0)
//}
