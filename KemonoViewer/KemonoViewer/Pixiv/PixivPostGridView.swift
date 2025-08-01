//
//  PixivPostGridView.swift
//  KemonoViewer
//
//  Created on 2025/7/29.
//

import SwiftUI

struct PixivPostGridView: View {
    
    private static let initialColumns = 3
    @Binding var postsData: [PixivPost_show]
    let artistSelectedData: PixivArtist_show?
    @Binding var postSelectedIndex: Int?
    
    @State private var hasCapturedInitialSize = false
    @State private var capturedSize: CGSize = .zero
    
    @State private var scrollToTop = false
    @State private var scrollToBottom = false
    
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    @Binding var autoScrollToFirstNotViewedImage: Bool
    
    let tagNotViewAction: (Int, Bool) -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollViewReader { proxy in
                ScrollView {
                    if let artistSelectedData {
                        Color.clear
                            .frame(height: 0)
                            .id("topAnchor")
                        LazyVGrid(columns: gridColumns) {
                            ForEach(postsData.indices, id: \.self) { postIndex in
                                GeometryReader { geo in
                                    VStack(alignment: .leading) {
                                        Button(action: {
                                            postSelectedIndex = postIndex
                                        }) {
                                            PixivPostGridItemView(
                                                postData: postsData[postIndex],
                                                size: geo.size.width,
                                                initialSize: capturedSize.width,
                                                imageURL: getPostCoverURL(artistFolderName: artistSelectedData.folderName, postIndex: postIndex),
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
                                        .cornerRadius(8.0)
                                        .aspectRatio(1.0, contentMode: .fit)
                                        Text(postsData[postIndex].name)
                                            .font(.system(size: 15))
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 3)
                                            .lineLimit(1)
                                    }
                                }
                                .aspectRatio(0.85, contentMode: .fit)
                                .id(Int(postIndex))
                            }
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
                        Color.clear
                            .frame(height: 0)
                            .id("bottomAnchor")
                    }
                    
                }
            }
            if artistSelectedData != nil {
                ScrollToTopBottomButton(scrollToTop: $scrollToTop, scrollToBottom: $scrollToBottom)
            }
        }
    }
    
    private func getPostCoverURL(artistFolderName: String, postIndex: Int) -> URL? {
        return URL(filePath: Constants.pixivBaseDir)
            .appendingPathComponent(artistFolderName)
            .appendingPathComponent(postsData[postIndex].folderName)
            .appendingPathComponent(postsData[postIndex].coverName)
    }
    
}

//#Preview {
//    PixivPostGridView()
//}
