//
//  KContentSelectView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

enum PostTab: String, CaseIterable {
    case listTab = "list.bullet"
    case imageTab = "square.grid.2x2"
}

struct KContentSelectView: View {
    @State private var artistSelectedData: Artist_show?
    @State private var postSelectedIndex: Int?
    @State private var postsData = [Post_show]()
    
    @State private var selectedTab: PostTab = .listTab
    
    @State private var onlyShowNotViewedPost = false
    
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
                VStack {
                    HStack {
                        PostTabView(selectedTab: $selectedTab)
                        Divider()
//                            .frame(minWidth: 0)
                        Toggle(isOn: $onlyShowNotViewedPost) {
                            Text("Only show unread post")
                        }
                    }
                    Group {
                        HSplitView {
                            if selectedTab == .imageTab {
                                PostGridView(
                                    postsData: $postsData,
                                    artistSelectedData: $artistSelectedData,
                                    postSelectedIndex: $postSelectedIndex,
                                    onlyShowNotViewedPost: onlyShowNotViewedPost
                                )
                                .frame(minWidth: 200, maxWidth: .infinity)
                            } else {
                                PostListView(
                                    postsData: $postsData,
                                    postSelectedIndex: $postSelectedIndex,
                                    artistSelectedId: artistSelectedData?.id,
                                    onlyShowNotViewedPost: onlyShowNotViewedPost
                                )
                                //  .frame(idealWidth: 100)
                            }
                            PostImageView(
                                postsData: $postsData,
                                artistSelectedData: $artistSelectedData,
                                postSelectedIndex: postSelectedIndex
                            )
                            .frame(maxWidth: .infinity)
                            //                                .layoutPriority(1)
                            
                        }
                    }
                    .layoutPriority(1)
                }
                .layoutPriority(1)
                
            }
        }
    }
}

struct PostTabView: View {
    
    @Binding var selectedTab: PostTab
    
    var body: some View {
        HStack {
            ForEach(PostTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack {
                        // 动态切换填充/非填充图标
                        Image(systemName: tab.rawValue)
                            .font(.title)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
//                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 1)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    KContentSelectView()
}
