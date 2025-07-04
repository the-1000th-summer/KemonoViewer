//
//  ArtistListView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct Artist_show: Hashable {
    let name: String
    let id: Int64
}

struct ArtistListView: View {
    @State private var artistsData = [Artist_show]()
//    @State private var artist
    @Binding var artistSelectedData: Artist_show?
    
    var body: some View {
        List(artistsData, id: \.self, selection: $artistSelectedData) { artistData in
            Text(artistData.name)
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
        .onAppear {
            artistsData = DataReader.readArtistData() ?? []
        }
        .navigationTitle("Oceans")
//        .onChange(of: selectedId) {
//            print("Selected: \(selectedId)")
//        }
        
    }
    
    private func tagArtistAllPost(artistData: Artist_show, viewed: Bool) {
        DatabaseManager.shared.tagArtist(artistId: artistData.id, viewed: viewed)
    }
}

#Preview {
    ArtistListView(artistSelectedData: .constant(Artist_show(name: "5924557", id: 1)))
}
