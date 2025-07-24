//
//  PixivRichListView.swift
//  KemonoViewer
//
//  Created on 2025/7/24.
//

import SwiftUI

struct PixivRichListView: View {
    @Binding var artistsData: [PixivArtist_show]
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
                            PixivArtistGridItemView(
                                artistData: artistsData[artistIndex],
                                size: geo.size,
//                                isSelected: (artistSelectedIndex != nil) ? artistsData[artistIndex].id == (artistsData[artistSelectedIndex!].id) : false
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: geo.size.width)
                    }
                    .cornerRadius(8.0)
                    .frame(height: 130)
                }
            }
        }
    }
}

//#Preview {
//    PixivRichListView()
//}
