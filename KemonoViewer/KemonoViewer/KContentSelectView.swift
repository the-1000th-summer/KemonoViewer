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

struct ArtistQueryConfig: Equatable {
    var onlyShowNotFullyViewedArtist: Bool = false
}

struct KContentSelectView: View {
    @State private var artistsData = [Artist_show]()
//    @State private var artistSelectedData: Artist_show?
    @State private var artistSelectedIndex: Int?
    
    @State private var postsData = [Post_show]()
    @State private var postSelectedIndex: Int?
    
    @State private var selectedTab: PostTab = .listTab
    @State private var selectedArtistTab: PostTab = .listTab
    
    @State private var artistQueryConfig = ArtistQueryConfig()
    @State private var postQueryConfig = PostQueryConfig()
    
    @State private var isProcessing = false
    @State private var readingProgress: Double = 0.0
    @State private var currentTask: Task<Void, Never>?
    
    @State private var isLoadingArtists = false
    @State private var isLoadingPosts = false
    
    private let pub = NotificationCenter.default.publisher(for: .updateNewViewedPostData)
    private let viewedPub = NotificationCenter.default.publisher(for: .updateAllPostViewedStatus)
    
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
                    HStack {
                        PostTabView(selectedTab: $selectedArtistTab)
                        ArtistQueryView(queryConfig: $artistQueryConfig)
                    }
                    
                    if isLoadingArtists {
                        VStack {
                            Spacer()
                            LoadingDataView()
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
                        artistsData = await DataReader.readArtistData(queryConfig: artistQueryConfig) ?? []
                        isLoadingArtists = false
                    }
                }
                VStack {
                    HStack {
                        PostTabView(selectedTab: $selectedTab)
                        Divider()
                        PostQueryView(queryConfig: $postQueryConfig)
                    }
                    .padding([.leading, .trailing])
                    
                    HStack {
                        if isLoadingPosts {
                            VStack {
                                Spacer()
                                LoadingDataView()
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            if selectedTab == .imageTab {
                                PostGridView(
                                    postsData: $postsData,
                                    artistSelectedData: (artistSelectedIndex != nil) ? artistsData[artistSelectedIndex!] : nil,
                                    postSelectedIndex: $postSelectedIndex,
                                    queryConfig: postQueryConfig,
                                    tagNotViewAction: { postIndex, viewed in
                                        newViewedStatusPost(postIndex: postIndex, viewed: viewed)
                                    }
                                )
                                .frame(minWidth: 200, maxWidth: .infinity)
                            } else {
                                PostListView(
                                    postsData: $postsData,
                                    postSelectedIndex: $postSelectedIndex,
                                    queryConfig: postQueryConfig,
                                    tagNotViewAction: { postIndex, viewed in
                                        newViewedStatusPost(postIndex: postIndex, viewed: viewed)
                                    }
                                )
                                //  .frame(idealWidth: 100)
                            }
                        }
                        
                        PostImageView(
                            postsData: $postsData,
                            artistData: (artistSelectedIndex != nil) ? artistsData[artistSelectedIndex!] : Artist_show(name: "", service: "", kemonoId: "", hasNotViewed: false, id: 0),
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
            .onChange(of: postSelectedIndex) {
                guard let postSelectedIndex else { return }
                newViewedStatusPost(postIndex: postSelectedIndex, viewed: true)
            }
            .onChange(of: postQueryConfig) {
                isLoadingPosts = true
                Task {
                    await refreshPostsData()
                    isLoadingPosts = false
                }
                postSelectedIndex = nil
            }
            .onChange(of: artistQueryConfig) {
                artistSelectedIndex = nil
                isLoadingArtists = true
                Task {
                    artistsData = await DataReader.readArtistData(queryConfig: artistQueryConfig) ?? []
                    isLoadingArtists = false
                }
            }
            .onReceive(pub) { notification in
                guard let viewedPostIndex = notification.userInfo?["viewedPostIndex"] as? Int else { return }
                newViewedStatusPost(postIndex: viewedPostIndex, viewed: true)
            }
            .onReceive(viewedPub) { notification in
                Task {
                    await refreshPostsData()
                }
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
            postsData = DataReader.readPostData(artistId: artistsData[artistSelectedIndex].id, queryConfig: postQueryConfig) ?? []
        } else {
            postsData = []
        }
    }
    
    private func newViewedStatusPost(postIndex: Int, viewed: Bool) {
        let originalPostData = postsData[postIndex]
        // prevent unnecessary view refreshing and database reading
        guard originalPostData.viewed != viewed else { return }
        
        postsData[postIndex] = Post_show(
            name: originalPostData.name,
            folderName: originalPostData.folderName,
            coverName: originalPostData.coverName,
            id: originalPostData.id,
            attNumber: originalPostData.attNumber,
            postDate: originalPostData.postDate,
            viewed: viewed
        )
        
        Task {
            await checkForArtistNotViewed()
            await DatabaseManager.shared.tagPost(postId: postsData[postIndex].id, viewed: viewed)
        }
    }
    
    private func checkForArtistNotViewed() async {
        let artist_hasNotViewed = artistsData[artistSelectedIndex!].hasNotViewed
        let posts_hasNotViewed = postsData.contains { !$0.viewed }
        if artist_hasNotViewed != posts_hasNotViewed {
            refreshArtistData(artistIndex: artistSelectedIndex!, hasNotViewed: posts_hasNotViewed)
        }
    }
    
    private func refreshArtistData(artistIndex: Int, hasNotViewed: Bool) {
        let artistData = artistsData[artistIndex]
        artistsData[artistIndex] = Artist_show(
            name: artistData.name,
            service: artistData.service,
            kemonoId: artistData.kemonoId,
            hasNotViewed: hasNotViewed,
            id: artistData.id
        )
    }
    
}

struct ArtistQueryView: View {
    @Binding var queryConfig: ArtistQueryConfig
    
    var body: some View {
        Toggle(isOn: $queryConfig.onlyShowNotFullyViewedArtist) {
            Text("Only show artists have unread post")
        }
    }
}

struct PostQueryView<CertainQueryConfig: QueryConfig>: View {
    @Binding var queryConfig: CertainQueryConfig
    
    var body: some View {
        HStack {
            Picker("Sort by", selection: $queryConfig.sortKey) {
                ForEach(CertainQueryConfig.SortKey.allCases, id: \.self) { sortKey in
                    Text(sortKey.rawValue)
                }
            }
            Picker("Order", selection: $queryConfig.sortOrder) {
                ForEach(SortOrder.allCases, id: \.self) { sortOrder in
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
