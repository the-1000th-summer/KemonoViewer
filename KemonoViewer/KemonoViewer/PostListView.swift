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
    
    var body: some View {
        List(postsData.indices, id: \.self, selection: $postSelectedIndex) { postCurrentIndex in
            Text(postsData[postCurrentIndex].name)
        }
        .onChange(of: artistSelectedId) {
            if let artistSelectedId {
                postsData = DataReader.readPostData(artistId: artistSelectedId) ?? []
            } else {
                postsData.removeAll()
            }
        }
    }
}

//#Preview {
//    PostListView(postSelectedId: .constant(0), artistSelectedId: 0)
//}
