//
//  PixivArtistView.swift
//  KemonoViewer
//
//  Created on 2025/7/23.
//

import SwiftUI

struct PixivArtist_show {
    let name: String
    let pixivId: String
    let hasNotViewed: Bool
    let id: Int64
}

struct PixivArtistListView: View {
    @Binding var artistsData: [PixivArtist_show]
    @Binding var artistSelectedIndex: Int?
    
    var body: some View {
        List(artistsData.indices, id: \.self, selection: $artistSelectedIndex) { artistIndex in
            HStack {
                Image(systemName: "circlebadge.fill")
                    .foregroundStyle(.blue)
                    .opacity(artistsData[artistIndex].hasNotViewed ? 1 : 0)
                Text(artistsData[artistIndex].name)
            }
            .contextMenu {
                Button("标记为全部已读") {
                    tagArtistAllPost(artistData: artistsData[artistIndex], viewed: true)
                    NotificationCenter.default.post(
                        name: .updateAllPostViewedStatus,
                        object: nil
                    )
                    refreshArtistData(artistIndex: artistIndex, hasNotViewed: false)
                }
                Button("标记为全部未读") {
                    tagArtistAllPost(artistData: artistsData[artistIndex], viewed: false)
                    NotificationCenter.default.post(
                        name: .updateAllPostViewedStatus,
                        object: nil
                    )
                    refreshArtistData(artistIndex: artistIndex, hasNotViewed: true)
                }
            }
        }
    }
    
    private func refreshArtistData(artistIndex: Int, hasNotViewed: Bool) {
        let artistData = artistsData[artistIndex]
        artistsData[artistIndex] = PixivArtist_show(
            name: artistData.name,
            pixivId: artistData.pixivId,
            hasNotViewed: hasNotViewed,
            id: artistData.id
        )
    }
    
    private func tagArtistAllPost(artistData: PixivArtist_show, viewed: Bool) {
        PixivDatabaseManager.shared.tagArtist(artistId: artistData.id, viewed: viewed)
    }
}


