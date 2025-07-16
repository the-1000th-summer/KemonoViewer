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
    var queryConfig: PostQueryConfig
    let tagNotViewAction: (Int, Bool) -> Void
    
    var body: some View {
        List(postsData.indices, id: \.self, selection: $postSelectedIndex) { postCurrentIndex in
            HStack {
                Image(systemName: "circlebadge.fill")
                    .foregroundStyle(.blue)
                    .opacity(postsData[postCurrentIndex].viewed ? 0 : 1)
                Text(postsData[postCurrentIndex].name)
            }
//            .selectionDisabled(true)
            .contextMenu {
                Button("标记为未读") {
                    tagNotViewAction(postCurrentIndex, false)
                }
            }
        }
    }
    
    private func refreshPostsData() {
        if let artistSelectedId {
            postsData = DataReader.readPostData(artistId: artistSelectedId, queryConfig: queryConfig) ?? []
        } else {
            postsData.removeAll()
        }
    }
    
    
    
}

//#Preview {
//    PostListView(postSelectedId: .constant(0), artistSelectedId: 0)
//}
