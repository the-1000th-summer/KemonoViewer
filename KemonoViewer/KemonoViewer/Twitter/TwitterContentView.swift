//
//  TwitterContentView.swift
//  KemonoViewer
//
//  Created on 2025/7/18.
//

import SwiftUI



struct TwitterContentView: View {
    
    @State private var artistsData = [TwitterArtist_show]()
    @State private var artistSelectedIndex: Int?
    
    @State private var selectedPostTab: PostTab = .listTab
    @State private var selectedArtistTab: PostTab = .listTab
    @State private var artistQueryConfig = ArtistQueryConfig()
    
    @State private var isLoadingArtists = false
    @State private var autoScrollToFirstNotViewedImage = true
    
    @State private var postQueryConfig = PostQueryConfig()
    
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
                        TwitterArtistListView(artistsData: $artistsData, artistSelectedIndex: $artistSelectedIndex)
                            .frame(minWidth: 150)
                    } else {
                        Text("Not Implemented.")
                    }
                }
            }
            .onAppear {
                isLoadingArtists = true
                Task {
                    artistsData = await TwitterDataReader.readArtistData(queryConfig: artistQueryConfig) ?? []
                    isLoadingArtists = false
                }
            }
            VStack {
                HStack {
                    PostQueryView(queryConfig: $postQueryConfig)
                    Toggle(isOn: $autoScrollToFirstNotViewedImage) {
                        Text("Scroll to first not viewed image")
                    }
                }
                .padding([.leading, .trailing])
                
                TweetImageView(
                    artistsData: $artistsData,
                    autoScrollToFirstNotViewedImage: $autoScrollToFirstNotViewedImage,
                    artistSelectedIndex: artistSelectedIndex, queryConfig: postQueryConfig
                )
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
            }
            .layoutPriority(1)
        }
    }
    

}

#Preview {
    TwitterContentView()
}
