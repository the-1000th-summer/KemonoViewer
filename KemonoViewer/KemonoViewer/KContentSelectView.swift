//
//  KContentSelectView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct KContentSelectView: View {
    @State private var artistSelectedId: Int64?
    @State private var postSelectedId: Int64?
    
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
                ArtistListView(artistSelectedId: $artistSelectedId)
                HSplitView {
                    PostListView(postSelectedId: $postSelectedId, artistSelectedId: artistSelectedId)
                        .layoutPriority(1)
                    PostImageView(postSelectedId: postSelectedId)
                        .layoutPriority(2)
                        .frame(maxWidth: .infinity)
                }
                
            }
        }
    }
}

#Preview {
    KContentSelectView()
}
