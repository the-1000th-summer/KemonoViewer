//
//  PixivContentView.swift
//  KemonoViewer
//
//  Created on 2025/7/18.
//

import SwiftUI
import Kingfisher

struct PixivContentView: View {
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
                    //                    PostQueryView(queryConfig: $postQueryConfig)
                    //                    Toggle(isOn: $autoScrollToFirstNotViewedImage) {
                    //                        Text("Scroll to first not viewed post")
                    //                    }
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
                            //                            PostGridView(
                            //                                postsData: $postsData,
                            //                                artistSelectedData: (artistSelectedIndex != nil) ? artistsData[artistSelectedIndex!] : nil,
                            //                                postSelectedIndex: $postSelectedIndex,
                            //                                autoScrollToFirstNotViewedImage: $autoScrollToFirstNotViewedImage,
                            //                                queryConfig: postQueryConfig,
                            //                                tagNotViewAction: { postIndex, viewed in
                            //                                    updateDB_newViewedStatusPost(postIndex: postIndex, viewed: viewed)
                            //                                    updateUI_newViewedStatusPost(postIndex: postIndex, viewed: viewed)
                            //                                    updateUI_newViewedStatisArtist()
                            //                                }
                            //
                            //                            )
                            Text("not implemented")
                                .frame(minWidth: 200, maxWidth: .infinity)
                        } else {
                            PixivPostListView(
                                postsData: $postsData,
                                postSelectedIndex: $postSelectedIndex,
                                //                                queryConfig: postQueryConfig,
                                //                                tagNotViewAction: { postIndex, viewed in
                                //                                    updateDB_newViewedStatusPost(postIndex: postIndex, viewed: viewed)
                                //                                    updateUI_newViewedStatusPost(postIndex: postIndex, viewed: viewed)
                                //                                    updateUI_newViewedStatisArtist()
                                //                                }
                            )
                            //  .frame(idealWidth: 100)
                        }
                    }
                    
                    PixivPostImageView(
                        artistsData: $artistsData,
                        postsData: $postsData,
                        artistSelectedIndex: artistSelectedIndex,
                        postSelectedIndex: postSelectedIndex,
//                        postQueryConfig: postQueryConfig
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
    }
    
    private func reloadPostsData() async {
        if let artistSelectedIndex {
            postsData = PixivDataReader.readPostData(artistId: artistsData[artistSelectedIndex].id, queryConfig: postQueryConfig) ?? []
        } else {
            postsData = []
        }
    }
}

#Preview {
    PixivContentView()
}
