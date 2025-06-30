//
//  PostListView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct PostListView: View {
    @State private var postsData = [Post_show]()
    @Binding var postSelectedId: Int64?
    var artistSelectedId: Int64?
    
    var body: some View {
        List(postsData, id: \.id, selection: $postSelectedId) { postData in
            Text(postData.name)
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

#Preview {
    PostListView(postSelectedId: .constant(0), artistSelectedId: 0)
}
