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
    
    private let pub = NotificationCenter.default.publisher(for: .updatePostTableViewData)
    
    var body: some View {
        List(postsData.indices, id: \.self, selection: $postSelectedIndex) { postCurrentIndex in
            HStack {
                Image(systemName: "circlebadge.fill")
                    .opacity(postsData[postCurrentIndex].viewed ? 0 : 1)
                Text(postsData[postCurrentIndex].name)
            }
            
        }
        .onChange(of: artistSelectedId) {
            if let artistSelectedId {
                postsData = DataReader.readPostData(artistId: artistSelectedId) ?? []
            } else {
                postsData.removeAll()
            }
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
        DatabaseManager.shared.tagViewedPost(viewedPostId: postsData[viewedPostIndex].id)
    }
    
}

//#Preview {
//    PostListView(postSelectedId: .constant(0), artistSelectedId: 0)
//}
