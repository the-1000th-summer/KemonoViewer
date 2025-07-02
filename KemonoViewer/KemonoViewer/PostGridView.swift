//
//  PostGridView.swift
//  KemonoViewer
//
//  Created on 2025/7/2.
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct PostGridView: View {
    
    private static let initialColumns = 3
    @Binding var postsData: [Post_show]
    @Binding var artistSelectedData: Artist_show?
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    @State private var capturedSize: CGSize = .zero
    @State private var hasCapturedInitialSize = false
    
    var body: some View {
        ScrollView {
            if let artistSelectedData {
                LazyVGrid(columns: gridColumns) {
                    ForEach(postsData.indices, id: \.self) { postIndex in
                        GeometryReader { geo in
                            PostGridItemView(
                                size: geo.size.width,
                                initialSize: capturedSize.width,
                                imageURL: getPostCoverURL(postIndex: postIndex, artistName: artistSelectedData.name),
                                postData: $postsData[postIndex]
                            )
                            .preference(key: SizePreferenceKey.self, value: geo.size)
                            
                        }
                        .cornerRadius(8.0)
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
                .onPreferenceChange(SizePreferenceKey.self) { size in
                    if !hasCapturedInitialSize && size != .zero {
                        capturedSize = size
                        hasCapturedInitialSize = true
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
