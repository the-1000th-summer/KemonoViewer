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
    @State private var artistsData = [KemonoArtist_show]()
    @State private var artistSelectedIndex: Int?
    
    @State private var postsData = [Post_show]()
    @State private var postSelectedIndex: Int?
    
    @State private var selectedTab: PostTab = .listTab
    @State private var selectedArtistTab: PostTab = .listTab
    
    @State private var artistQueryConfig = ArtistQueryConfig()
    @State private var postQueryConfig = KemonoPostQueryConfig()
    
    @State private var isProcessing = false
    @State private var readingProgress: Double = 0.0
    @State private var currentTask: Task<Void, Never>?
    
    @State private var isLoadingArtists = false
    @State private var isLoadingPosts = false
    
    @State private var autoScrollToFirstNotViewedImage = true
    
    @StateObject private var windowOpenState = WindowOpenStatusManager.shared
    
    private let onePostViewedPub = NotificationCenter.default.publisher(for: .updateNewViewedKemonoPostUI)
    private let viewedPub = NotificationCenter.default.publisher(for: .updateAllKemonoPostViewedStatus)
    private let fullScrViewClosedPub = NotificationCenter.default.publisher(for: .kemonoFullScreenViewClosed)
    
    var body: some View {
        VStack {
            HStack {
                Button("Load Data") {
                    isProcessing = true
                    currentTask = Task {
                        await KemonoDataWriter.writeKemonoDataToDatabase(isProcessing: $isProcessing, progress: $readingProgress)
                    }
                    isProcessing = false
                }
                .padding()
                Button("Load data 2") {
//                    isProcessing = true
                    currentTask = Task {
                        await KemonoDataWriter.getDataFromKemonoApi(isProcessing: $isProcessing, progress: $readingProgress)
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
                            KemonoArtistListView(artistsData: $artistsData, artistSelectedIndex: $artistSelectedIndex)
                                .frame(minWidth: 150)
                        } else {
                            KemonoArtistRichListView(artistsData: $artistsData, artistSelectedIndex: $artistSelectedIndex)
                                .frame(minWidth: 200, maxWidth: 480)
                        }
                    }
                    
                }
                .onAppear {
                    isLoadingArtists = true
                    Task {
                        artistsData = await KemonoDataReader.readArtistData(queryConfig: artistQueryConfig) ?? []
                        isLoadingArtists = false
                    }
                }
                VStack {
                    HStack {
                        PostTabView(selectedTab: $selectedTab)
                        Divider()
                        PostQueryView(queryConfig: $postQueryConfig)
                        Toggle(isOn: $autoScrollToFirstNotViewedImage) {
                            Text("Scroll to first not viewed post")
                        }
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
                                    autoScrollToFirstNotViewedImage: $autoScrollToFirstNotViewedImage,
                                    tagNotViewAction: { postIndex, viewed in
                                        updateDB_newViewedStatusPost(postIndex: postIndex, viewed: viewed)
                                        updateUI_newViewedStatusPost(postIndex: postIndex, viewed: viewed)
                                        updateUI_newViewedStatisArtist()
                                    }
                                    
                                )
                                .frame(minWidth: 200, maxWidth: .infinity)
                            } else {
                                PostListView(
                                    postsData: $postsData,
                                    postSelectedIndex: $postSelectedIndex,
                                    tagNotViewAction: { postIndex, viewed in
                                        updateDB_newViewedStatusPost(postIndex: postIndex, viewed: viewed)
                                        updateUI_newViewedStatusPost(postIndex: postIndex, viewed: viewed)
                                        updateUI_newViewedStatisArtist()
                                    }
                                )
                                //  .frame(idealWidth: 100)
                            }
                        }
                        
                        PostImageView(
                            postsData: $postsData,
                            artistsData: $artistsData,
                            artistSelectedIndex: $artistSelectedIndex,
                            postSelectedIndex: postSelectedIndex,
                            postQueryConfig: postQueryConfig
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
                    await reloadPostsData()
                    isLoadingPosts = false
                }
                postSelectedIndex = nil
            }
            .onChange(of: postSelectedIndex) {
                guard let postSelectedIndex else { return }
                updateDB_newViewedStatusPost(postIndex: postSelectedIndex, viewed: true)
                updateUI_newViewedStatusPost(postIndex: postSelectedIndex, viewed: true)
                updateUI_newViewedStatisArtist()
            }
            .onChange(of: postQueryConfig) {
                isLoadingPosts = true
                Task {
                    await reloadPostsData()
                    isLoadingPosts = false
                }
                postSelectedIndex = nil
            }
            .onChange(of: artistQueryConfig) {
                artistSelectedIndex = nil
                isLoadingArtists = true
                Task {
                    artistsData = await KemonoDataReader.readArtistData(queryConfig: artistQueryConfig) ?? []
                    isLoadingArtists = false
                }
            }
            .onReceive(onePostViewedPub) { notification in
                guard let currentArtistIdFromPointer = notification.userInfo?["currentArtistId"] as? Int64, let viewedPostId = notification.userInfo?["viewedPostId"] as? Int64, let currentArtistShouldUpdateUI = notification.userInfo?["currentArtistShouldUpdateUI"] as? Bool else { return }
                // PostImageView中选中的artist与全屏中浏览的artist可能不同
                if let artistSelectedIndex {
                    if artistsData[artistSelectedIndex].id == currentArtistIdFromPointer {
                        updateUI_newViewedStatusPost(postId: viewedPostId, viewed: true)
                    }
                }
                if currentArtistShouldUpdateUI {
                    refreshArtistData(artistId: currentArtistIdFromPointer, hasNotViewed: false)
                }
            }
            .onReceive(viewedPub) { notification in
                Task {
                    await reloadPostsData()
                }
            }
            .onReceive(fullScrViewClosedPub) { _ in
                if postQueryConfig.onlyShowNotViewedPost {
                    postSelectedIndex = nil
                    Task {
                        await reloadPostsData()
                    }
                }
            }
        }
        .sheet(isPresented: $isProcessing) {
            ProgressView("Processing...", value: readingProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()
                .interactiveDismissDisabled()
        }
        .onAppear { windowOpenState.kemonoMainOpened = true }
        .onDisappear { windowOpenState.kemonoMainOpened = false }
        
    }
    
    private func reloadPostsData() async {
        if let artistSelectedIndex {
            postsData = KemonoDataReader.readPostData(artistId: artistsData[artistSelectedIndex].id, queryConfig: postQueryConfig) ?? []
        } else {
            postsData = []
        }
    }
    
    private func updateUI_newViewedStatusPost(postId: Int64, viewed: Bool) {
        if let postIndex = postsData.firstIndex(where: { $0.id == postId }) {
            updateUI_newViewedStatusPost(postIndex: postIndex, viewed: viewed)
        }
    }
    
    private func updateUI_newViewedStatusPost(postIndex: Int, viewed: Bool) {
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
    }
    
    private func updateUI_newViewedStatisArtist() {
        Task {
            await checkForArtistNotViewed()
        }
    }
    
    private func updateDB_newViewedStatusPost(postIndex: Int, viewed: Bool) {
        Task {
            await KemonoDatabaseManager.shared.tagPost(postId: postsData[postIndex].id, viewed: viewed)
        }
    }
    
    private func checkForArtistNotViewed() async {
        let artist_hasNotViewed = artistsData[artistSelectedIndex!].hasNotViewed
        let posts_hasNotViewed = postsData.contains { !$0.viewed }
        if artist_hasNotViewed != posts_hasNotViewed {
            await MainActor.run {
                refreshArtistData(artistIndex: artistSelectedIndex!, hasNotViewed: posts_hasNotViewed)
            }
        }
    }
    
    private func refreshArtistData(artistId: Int64, hasNotViewed: Bool) {
        if let artistIndex = artistsData.firstIndex(where: { $0.id == artistId }) {
            refreshArtistData(artistIndex: artistIndex, hasNotViewed: hasNotViewed)
        }
    }
    
    private func refreshArtistData(artistIndex: Int, hasNotViewed: Bool) {
        let artistData = artistsData[artistIndex]
        artistsData[artistIndex] = KemonoArtist_show(
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
