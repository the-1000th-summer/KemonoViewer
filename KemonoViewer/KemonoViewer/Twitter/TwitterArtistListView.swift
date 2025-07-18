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
        }
    }
}

