//
//  ArtistListView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct Artist_show: Hashable {
    let name: String
    let service: String
    let kemonoId: String
    let hasNotviewed: Bool
    let id: Int64
}

struct ArtistListView: View {
    @Binding var artistsData: [Artist_show]
    @Binding var artistSelectedData: Artist_show?
    
    var body: some View {
        List(artistsData, id: \.self, selection: $artistSelectedData) { artistData in
            HStack {
                Image(systemName: "circlebadge.fill")
                    .foregroundStyle(.blue)
                    .opacity(artistData.hasNotviewed ? 1 : 0)
                Text(artistData.name)
            }
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
        .navigationTitle("Oceans")
        
    }
    
    private func tagArtistAllPost(artistData: Artist_show, viewed: Bool) {
        DatabaseManager.shared.tagArtist(artistId: artistData.id, viewed: viewed)
    }
}

