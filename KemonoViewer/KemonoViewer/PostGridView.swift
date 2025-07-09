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
    @Binding var postSelectedIndex: Int?
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    @State private var capturedSize: CGSize = .zero
    @State private var hasCapturedInitialSize = false
    
    var onlyShowNotViewedPost: Bool
    
    var body: some View {
        ScrollView {
            if let artistSelectedData {
                LazyVGrid(columns: gridColumns) {
                    ForEach(postsData.indices, id: \.self) { postIndex in
                        GeometryReader { geo in
                            Button(action: {
                                postSelectedIndex = postIndex
                                newViewedPost(viewedPostIndex: postIndex)
                            }) {
                                PostGridItemView(
                                    postData: postsData[postIndex],
                                    size: geo.size.width,
                                    initialSize: capturedSize.width,
                                    imageURL: getPostCoverURL(postIndex: postIndex, artistName: artistSelectedData.name),
                                    isSelected: postSelectedIndex == postIndex
                                )
                                .preference(key: SizePreferenceKey.self, value: geo.size)
                                .contextMenu {
                                    Button("标记为未读") {
                                        newNotViewedPost(notViewedPostIndex: postIndex)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
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
                .onChange(of: onlyShowNotViewedPost) {
                    refreshPostsData()
                    postSelectedIndex = nil
                }
            }
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
    
    private func refreshPostsData() {
        if let artistSelectedData {
            postsData = DataReader.readPostData(artistId: artistSelectedData.id, notViewedToggleisOn: onlyShowNotViewedPost) ?? []
        } else {
            postsData.removeAll()
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
