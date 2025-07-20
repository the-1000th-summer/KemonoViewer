//
//  TwitterArtistListView.swift
//  KemonoViewer
//
//  Created on 2025/7/18.
//

import SwiftUI

struct TwitterArtist_show: Hashable {
    let name: String
    let twitterId: String
    let hasNotViewed: Bool
    let id: Int64
}

struct TwitterArtistListView: View {
    
    @Binding var artistsData: [TwitterArtist_show]
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
                    tagArtistAllImages(artistData: artistsData[artistIndex], viewed: true)
                    NotificationCenter.default.post(
                        name: .updateAllTwitterImageViewedStatus,
                        object: nil
                    )
                    refreshArtistData(artistIndex: artistIndex, hasNotViewed: false)
                }
                Button("标记为全部未读") {
                    tagArtistAllImages(artistData: artistsData[artistIndex], viewed: false)
                    NotificationCenter.default.post(
                        name: .updateAllTwitterImageViewedStatus,
                        object: nil
                    )
                    refreshArtistData(artistIndex: artistIndex, hasNotViewed: true)
                }
            }
        }
    }
    
    private func refreshArtistData(artistIndex: Int, hasNotViewed: Bool) {
        let artistData = artistsData[artistIndex]
        artistsData[artistIndex] = TwitterArtist_show(
            name: artistData.name,
            twitterId: artistData.twitterId,
            hasNotViewed: hasNotViewed,
            id: artistData.id
        )
    }
    
    private func tagArtistAllImages(artistData: TwitterArtist_show, viewed: Bool) {
        TwitterDatabaseManager.shared.tagArtist(artistId: artistData.id, viewed: viewed)
    }
}

