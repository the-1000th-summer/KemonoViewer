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
    
    @State private var scrollToTop = false
    @State private var scrollToBottom = false
    
    @Binding var autoScrollToFirstNotViewedImage: Bool
    
    var queryConfig: PostQueryConfig
    let tagNotViewAction: (Int, Bool) -> Void

    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollViewReader { proxy in
                ScrollView {
                    if let artistSelectedData {
                        LazyVGrid(columns: gridColumns) {
                            Color.clear
                                .frame(height: 0)
                                .id("topAnchor")
                            ForEach(postsData.indices, id: \.self) { postIndex in
                                GeometryReader { geo in
                                    Button(action: {
                                        postSelectedIndex = postIndex
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
                                                tagNotViewAction(postIndex, false)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .cornerRadius(8.0)
                                .aspectRatio(1, contentMode: .fit)
                                .id(Int(postIndex))
                            }
                            Color.clear
                                .frame(height: 0)
                                .id("bottomAnchor")
                        }
                        .onAppear {
                            if autoScrollToFirstNotViewedImage {
                                guard let firstNotViewedIndex: Int = postsData.firstIndex(where: { !$0.viewed }) else { return }
                                proxy.scrollTo(firstNotViewedIndex, anchor: .top)
                            }
                        }
                        .onChange(of: scrollToTop) {
                            proxy.scrollTo("topAnchor", anchor: .top)
                        }
                        .onChange(of: scrollToBottom) {
                            proxy.scrollTo("bottomAnchor", anchor: .bottom)
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
            if artistSelectedData != nil {
                ScrollToTopBottomButton(scrollToTop: $scrollToTop, scrollToBottom: $scrollToBottom)
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
