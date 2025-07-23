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
    
    @State private var selectedArtistTab: PostTab = .listTab
    
    @State private var isLoadingArtists = false

    var body: some View {
        HSplitView {
            VStack {
                HStack {
                    PostTabView(selectedTab: $selectedArtistTab)
//                    ArtistQueryView(queryConfig: $artistQueryConfig)
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
//                        ArtistRichListView(artistsData: $artistsData, artistSelectedIndex: $artistSelectedIndex)
//                            .frame(minWidth: 200, maxWidth: 480)
                    }
                }
            }
        }
    }
}

#Preview {
    PixivContentView()
}
