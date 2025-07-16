//
//  ArtistRichListView.swift
//  KemonoViewer
//
//  Created on 2025/7/15.
//

import SwiftUI

struct ArtistRichListView: View {
    @Binding var artistsData: [Artist_show]
    @Binding var artistSelectedData: Artist_show?
    private static let initialColumns = 1
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns) {
                ForEach(artistsData, id: \.self) { artistData in
                    GeometryReader { geo in
                        Button(action: {
                            artistSelectedData = artistData
                        }) {
                            ArtistGridItemView(
                                artistData: artistData,
                                size: geo.size,
                                isSelected: artistData.id == (artistSelectedData?.id ?? 0)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: geo.size.width)
                        .contextMenu {
                            Button("标记为全部已读") {
                                tagArtistAllPost(artistData: artistData, viewed: true)
                                NotificationCenter.default.post(
                                    name: .updateAllPostViewedStatus,
                                    object: nil
                                )
                            }
                            Button("标记为全部未读") {
                                tagArtistAllPost(artistData: artistData, viewed: false)
                                NotificationCenter.default.post(
                                    name: .updateAllPostViewedStatus,
                                    object: nil
                                )
                            }
                        }
                    }
                    .cornerRadius(8.0)
                    .frame(height: 130)
                }
            }
        }
    }
    
    private func tagArtistAllPost(artistData: Artist_show, viewed: Bool) {
        DatabaseManager.shared.tagArtist(artistId: artistData.id, viewed: viewed)
    }
}

