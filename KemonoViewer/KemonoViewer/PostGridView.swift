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
    let artistSelectedData: Artist_show?
    @Binding var postSelectedIndex: Int?
    
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    @State private var capturedSize: CGSize = .zero
    @State private var hasCapturedInitialSize = false
    
    var queryConfig: QueryConfig
    private let pub = NotificationCenter.default.publisher(for: .updateNewViewedPostData)
    private let viewedPub = NotificationCenter.default.publisher(for: .updateAllPostViewedStatus)
    
    var body: some View {
        ScrollView {
            if let artistSelectedData {
                LazyVGrid(columns: gridColumns) {
                    ForEach(postsData.indices, id: \.self) { postIndex in
                        GeometryReader { geo in
                            Button(action: {
                                postSelectedIndex = postIndex
                                newViewedStatusPost(postIndex: postIndex, viewed: true)
                            }) {
                                PostGridItemView(
                                    postData: postsData[postIndex],
                                    size: geo.size.width,
                                    initialSize: capturedSize.width,
                                    imageURL: getPostCoverURL(postIndex: postIndex, artistName: artistSelectedData.name),
                                    isSelected: postSelectedIndex == postIndex
                                )
                                .contentShape(Rectangle())
                                .preference(key: SizePreferenceKey.self, value: geo.size)
                                .contextMenu {
                                    Button("标记为未读") {
                                        newViewedStatusPost(postIndex: postIndex, viewed: false)
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
                .onReceive(pub) { notification in
                    guard let viewedPostIndex = notification.userInfo?["viewedPostIndex"] as? Int else { return }
                    newViewedStatusPost(postIndex: viewedPostIndex, viewed: true)
                }
                .onReceive(viewedPub) { notification in
                    refreshPostsData()
                }
            }
        }
        
        
    }
    
    private func newViewedStatusPost(postIndex: Int, viewed: Bool) {
        let originalPostData = postsData[postIndex]
        postsData[postIndex] = Post_show(
            name: originalPostData.name,
            folderName: originalPostData.folderName,
            coverName: originalPostData.coverName,
            id: originalPostData.id,
            attNumber: originalPostData.attNumber,
            postDate: originalPostData.postDate,
            viewed: viewed
        )
        DatabaseManager.shared.tagPost(postId: postsData[postIndex].id, viewed: viewed)
    }
    
    private func refreshPostsData() {
        if let artistSelectedData {
            postsData = DataReader.readPostData(artistId: artistSelectedData.id, queryConfig: queryConfig) ?? []
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
