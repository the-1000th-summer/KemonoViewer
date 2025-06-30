//
//  KContentSelectView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct KContentSelectView: View {
    @State private var artistSelectedData: Artist_show?
    
    @State private var postSelectedIndex: Int?
    @State private var postsData = [Post_show]()
    
    var body: some View {
        VStack {
            HStack {
                Button("Load Data") {}
                    .padding()
                Button("Show Data") {}
                    .padding()
                Spacer()
            }
            HSplitView {
                ArtistListView(artistSelectedData: $artistSelectedData)
                HSplitView {
                    PostListView(
                        postsData: $postsData,
                        postSelectedIndex: $postSelectedIndex,
                        artistSelectedId: artistSelectedData?.id
                    )

                    PostImageView(
                        postsData: $postsData,
                        artistSelectedData: $artistSelectedData,
                        postSelectedIndex: postSelectedIndex
                    )

                        .frame(maxWidth: .infinity)
                }
                
            }
        }
    }
}

#Preview {
    KContentSelectView()
}
