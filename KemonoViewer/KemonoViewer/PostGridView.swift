//
//  PostGridView.swift
//  KemonoViewer
//
//  Created on 2025/7/2.
//

import SwiftUI

struct PostGridView: View {
    
    private static let initialColumns = 3
    @Binding var postsData: [Post_show]
    @Binding var artistSelectedData: Artist_show?
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    var body: some View {
        ScrollView {
            if let artistSelectedData {
                LazyVGrid(columns: gridColumns) {
                    ForEach(postsData.indices, id: \.self) { postIndex in
                        GeometryReader { geo in
                            GridItemView(
                                size: geo.size.width,
                                imageURL: getPostCoverURL(postIndex: postIndex, artistName: artistSelectedData.name))
                        }
                        .cornerRadius(8.0)
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        
    }
    
    private func getPostCoverURL(postIndex: Int, artistName: String) -> URL {
        return URL(filePath: "/Volumes/ACG/kemono")
            .appendingPathComponent(artistName)
            .appendingPathComponent(postsData[postIndex].folderName)
            .appendingPathComponent(postsData[postIndex].coverName)
    }
}

//#Preview {
//    PostGridView()
//}
