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

struct QueryConfig: Equatable {
    enum SortKey: String, CaseIterable {
        case date = "post_date"
        case postTitle = "name"
    }
    
    enum SortOrder: String, CaseIterable {
        case ascending = "arrowtriangle.up.fill"
        case descending = "arrowtriangle.down.fill"
    }
    
    var sortKey: SortKey = .date
    var sortOrder: SortOrder = .ascending
    var onlyShowNotViewedPost: Bool = false
}

struct KContentSelectView: View {
    @State private var artistsData = [Artist_show]()
//    @State private var artistSelectedData: Artist_show?
    @State private var artistSelectedIndex: Int?
    
    @State private var postsData = [Post_show]()
    @State private var postSelectedIndex: Int?
    
    @State private var selectedTab: PostTab = .listTab
    @State private var selectedArtistTab: PostTab = .listTab
    
    @State private var queryConfig = QueryConfig()
    
    @State private var isProcessing = false
    @State private var readingProgress: Double = 0.0
    @State private var currentTask: Task<Void, Never>?
    
    @State private var isLoadingArtists = false
    @State private var isLoadingPosts = false
    
    
    
    var body: some View {
        VStack {
            HStack {
                Button("Load Data") {
                    isProcessing = true
                    currentTask = Task {
                        await DataWriter.writeKemonoDataToDatabase(isProcessing: $isProcessing, progress: $readingProgress)
                    }
                    isProcessing = false
                }
                .padding()
                Button("Load data 2") {
//                    isProcessing = true
                    currentTask = Task {
                        await DataWriter.getDataFromKemonoApi(isProcessing: $isProcessing, progress: $readingProgress)
                    }
//                    DataWriter.getDataFromKemonoApi(isProcessing: $isProcessing, progress: $readingProgress)
                    
//                    isProcessing = false
                }
                .padding()
                Spacer()
            }
            HSplitView {
                VStack {
                    PostTabView(selectedTab: $selectedArtistTab)
                    if isLoadingArtists {
                        VStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        if selectedArtistTab == .listTab {
                            ArtistListView(artistsData: $artistsData, artistSelectedIndex: $artistSelectedIndex)
                                .frame(minWidth: 150)
                        } else {
                            ArtistRichListView(artistsData: $artistsData, artistSelectedIndex: $artistSelectedIndex)
                                .frame(minWidth: 200, maxWidth: 480)
                        }
                    }
                    
                }
                .onAppear {
                    isLoadingArtists = true
                    Task {
                        artistsData = await DataReader.readArtistData() ?? []
                        isLoadingArtists = false
                    }
                }
                VStack {
                    HStack {
                        PostTabView(selectedTab: $selectedTab)
                        Divider()
                        PostQueryView(queryConfig: $queryConfig)
                    }
                    .padding([.leading, .trailing])
                    
                    HStack {
                        if isLoadingPosts {
                            VStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            if selectedTab == .imageTab {
                                PostGridView(
                                    postsData: $postsData,
                                    artistSelectedData: (artistSelectedIndex != nil) ? artistsData[artistSelectedIndex!] : nil,
                                    postSelectedIndex: $postSelectedIndex,
                                    queryConfig: queryConfig
                                )
                                .frame(minWidth: 200, maxWidth: .infinity)
                            } else {
                                PostListView(
                                    postsData: $postsData,
                                    postSelectedIndex: $postSelectedIndex,
                                    artistSelectedId: (artistSelectedIndex != nil) ? artistsData[artistSelectedIndex!].id : nil,
                                    queryConfig: queryConfig
                                )
                                //  .frame(idealWidth: 100)
                            }
                        }
                        
                        PostImageView(
                            postsData: $postsData,
                            artistName: (artistSelectedIndex != nil) ? artistsData[artistSelectedIndex!].name : "(No artist name)",
                            postSelectedIndex: postSelectedIndex
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .layoutPriority(1)
                    
                    
                }
                .layoutPriority(1)
                
            }
            .onChange(of: artistSelectedIndex) {
                isLoadingPosts = true
                Task {
                    await refreshPostsData()
                    isLoadingPosts = false
                }
                
                postSelectedIndex = nil
            }
            .onChange(of: queryConfig) {
                Task {
                    await refreshPostsData()
                    isLoadingPosts = false
                }
                postSelectedIndex = nil
            }
        }
        .sheet(isPresented: $isProcessing) {
            ProgressView("Processing...", value: readingProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()
                .interactiveDismissDisabled()
        }
        
    }
    
    private func refreshPostsData() async {
        if let artistSelectedIndex {
            postsData = DataReader.readPostData(artistId: artistsData[artistSelectedIndex].id, queryConfig: queryConfig) ?? []
        } else {
            postsData = []
        }
    }
    
}

struct PostQueryView: View {
    @Binding var queryConfig: QueryConfig
    
    var body: some View {
        HStack {
            Picker("Sort by", selection: $queryConfig.sortKey) {
                ForEach(QueryConfig.SortKey.allCases, id: \.self) { sortKey in
                    Text(sortKey.rawValue)
                }
            }
            Picker("Order", selection: $queryConfig.sortOrder) {
                ForEach(QueryConfig.SortOrder.allCases, id: \.self) { sortOrder in
                    Image(systemName: sortOrder.rawValue)
                }
            }
            .pickerStyle(.segmented)
            Toggle(isOn: $queryConfig.onlyShowNotViewedPost) {
                Text("Only show unread post")
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
