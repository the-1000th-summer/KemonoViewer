//
//  ArtistListView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct KemonoArtist_show: Hashable, Codable {
    let name: String
    let service: String
    let kemonoId: String
    let hasNotViewed: Bool
    let id: Int64
}

struct KemonoArtistListView: View {
    @Binding var artistsData: [KemonoArtist_show]
//    @Binding var artistSelectedData: Artist_show?
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
                        name: .updateAllKemonoPostViewedStatus,
                        object: nil
                    )
                    refreshArtistData(artistIndex: artistIndex, hasNotViewed: false)
                }
                Button("标记为全部未读") {
                    tagArtistAllPost(artistData: artistsData[artistIndex], viewed: false)
                    NotificationCenter.default.post(
                        name: .updateAllKemonoPostViewedStatus,
                        object: nil
                    )
                    refreshArtistData(artistIndex: artistIndex, hasNotViewed: true)
                }
            }
        }
        .navigationTitle("Oceans")
        
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
    
    private func tagArtistAllPost(artistData: KemonoArtist_show, viewed: Bool) {
        KemonoDatabaseManager.shared.tagArtist(artistId: artistData.id, viewed: viewed)
    }
}

