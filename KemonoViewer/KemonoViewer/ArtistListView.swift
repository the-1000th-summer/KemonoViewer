//
//  ArtistListView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct Artist_show {
    let name: String
    let id: Int64
}

struct ArtistListView: View {
    @State private var artistsData = [Artist_show]()
//    @State private var artist
    @Binding var artistSelectedId: Int64?
    
    var body: some View {
        List(artistsData, id: \.id, selection: $artistSelectedId) { artistData in
            Text(artistData.name)
        }
        .onAppear {
            artistsData = DataReader.readArtistData() ?? []
        }
        .navigationTitle("Oceans")
//        .onChange(of: selectedId) {
//            print("Selected: \(selectedId)")
//        }
        
    }
}

#Preview {
    ArtistListView(artistSelectedId: .constant(0))
}
