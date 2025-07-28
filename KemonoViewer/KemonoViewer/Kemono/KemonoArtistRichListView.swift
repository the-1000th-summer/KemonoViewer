//
//  ArtistRichListView.swift
//  KemonoViewer
//
//  Created on 2025/7/15.
//

import SwiftUI

struct KemonoArtistRichListView: View {
    @Binding var artistsData: [KemonoArtist_show]
//    @Binding var artistSelectedData: Artist_show?
    @Binding var artistSelectedIndex: Int?
    
    private static let initialColumns = 1
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns) {
                ForEach(artistsData.indices, id: \.self) { artistIndex in
                    GeometryReader { geo in
                        Button(action: {
                            artistSelectedIndex = artistIndex
                        }) {
                            ArtistGridItemView(
                                artistData: artistsData[artistIndex],
                                size: geo.size,
                                isSelected: (artistSelectedIndex != nil) ? artistsData[artistIndex].id == (artistsData[artistSelectedIndex!].id) : false
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: geo.size.width)
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
                    .cornerRadius(8.0)
                    .frame(height: 130)
                }
            }
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
    
    private func tagArtistAllPost(artistData: KemonoArtist_show, viewed: Bool) {
        KemonoDatabaseManager.shared.tagArtist(artistId: artistData.id, viewed: viewed)
    }
}

