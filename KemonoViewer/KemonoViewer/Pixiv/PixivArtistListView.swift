//
//  PixivArtistView.swift
//  KemonoViewer
//
//  Created on 2025/7/23.
//

import SwiftUI

struct PixivArtist_show {
    let name: String
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
        }
    }
}


