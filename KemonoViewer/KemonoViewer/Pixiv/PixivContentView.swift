//
//  PixivContentView.swift
//  KemonoViewer
//
//  Created on 2025/7/18.
//

import SwiftUI
import Kingfisher

struct PixivContentView: View {
    @Environment(\.appearsActive) private var windowIsActive
    @State private var artistsData = [PixivArtist_show]()
    @State private var artistSelectedIndex: Int?
    
    @State private var postsData = [PixivPost_show]()
    @State private var postSelectedIndex: Int?
    
    @State private var selectedTab: PostTab = .listTab
    @State private var selectedArtistTab: PostTab = .listTab
    
    @State private var artistQueryConfig = ArtistQueryConfig()
    @State private var postQueryConfig = PixivPostQueryConfig()
    
    @State private var isLoadingArtists = false
    @State private var isLoadingPosts = false
    
    @State private var autoScrollToFirstNotViewedImage = true
    
    @StateObject private var windowOpenState = WindowOpenStatusManager.shared
    
    private let onePostViewedPub = NotificationCenter.default.publisher(for: .updateNewViewedPixivPostUI)
    private let allViewedPub = NotificationCenter.default.publisher(for: .updateAllPixivPostViewedStatus)
    private let fullScrViewClosedPub = NotificationCenter.default.publisher(for: .pixivFullScreenViewClosed)

    var body: some View {
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
                        PixivArtistListView(artistsData: $artistsData, artistSelectedIndex: $artistSelectedIndex)
                            .frame(minWidth: 150)
                    } else {
                        PixivRichListView(artistsData: $artistsData, artistSelectedIndex: $artistSelectedIndex)
                            .frame(minWidth: 200, maxWidth: 480)
                    }
                }
            }
            .onAppear {
                isLoadingArtists = true
                Task {
                    artistsData = await PixivDataReader.readArtistData(queryConfig: artistQueryConfig) ?? []
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
                            PixivPostGridView(
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
                        } else {
                            PixivPostListView(
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
                    
                    PixivPostImageView(
                        artistsData: $artistsData,
                        postsData: $postsData,
                        artistSelectedIndex: artistSelectedIndex,
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
                artistsData = await PixivDataReader.readArtistData(queryConfig: artistQueryConfig) ?? []
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
        .onChange(of: windowIsActive) { wasActive, isNowActive in
            if isNowActive {
                NSApp.applicationIconImage = NSImage(named: "pixivIcon_round")
            }
        }
        .onReceive(allViewedPub) { notification in
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
        .onAppear { windowOpenState.pixivMainOpened = true }
        .onDisappear { windowOpenState.pixivMainOpened = false }
    }
    
    private func reloadPostsData() async {
        if let artistSelectedIndex {
            postsData = PixivDataReader.readPostData(artistId: artistsData[artistSelectedIndex].id, queryConfig: postQueryConfig) ?? []
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
        
        postsData[postIndex] = PixivPost_show(
            name: originalPostData.name,
            folderName: originalPostData.folderName,
            coverName: originalPostData.coverName,
            id: originalPostData.id,
            imageNumber: originalPostData.imageNumber,
            postDate: originalPostData.postDate,
            xRestrict: originalPostData.xRestrict,
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
            await PixivDatabaseManager.shared.tagPost(postId: postsData[postIndex].id, viewed: viewed)
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
        artistsData[artistIndex] = PixivArtist_show(
            name: artistData.name,
            folderName: artistData.folderName,
            pixivId: artistData.pixivId,
            avatarName: artistData.avatarName,
            backgroundName: artistData.backgroundName,
            hasNotViewed: hasNotViewed,
            id: artistData.id
        )
    }
}

#Preview {
    PixivContentView()
}
