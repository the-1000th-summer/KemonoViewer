//
//  TweetImageView.swift
//  KemonoViewer
//
//  Created on 2025/7/18.
//

import SwiftUI

struct TweetImageView: View {
    
    private static let initialColumns = 3
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    @State private var isLoadingData: Bool = false
    @State private var imagesName = [String]()
    
    @Binding var artistsData: [TwitterArtist_show]
    var artistSelectedIndex: Int?
    
    @ViewBuilder
    private func mainTweetImageView() -> some View {
        if isLoadingData {
            VStack {
                Spacer()
                LoadingDataView()
                Spacer()
            }
            
        } else {
            ScrollView {
                if let artistSelectedIndex {
                    if imagesName.isEmpty {
                        Text("No attachments in this post.")
                    } else {
                        LazyVGrid(columns: gridColumns) {
                            ForEach(imagesName.indices, id: \.self) { imageIndex in
                                GeometryReader { geo in
                                    Button(action: {
                                        
                                        openWindow(id: "fsViewer", value: fsWindowData)
                                    }) {
                                        PostImageGridItemView(
                                            size: geo.size.width,
                                            imageURL: getImageURL(artistId: artistsData[artistSelectedIndex].twitterId, imageName: imagesName[imageIndex]),
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .cornerRadius(8.0)
                                .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("Select artist to show image.")
                        Spacer()
                    }
                }
            }
        }
    }
    
    var body: some View {
        mainTweetImageView()
            .onChange(of: artistSelectedIndex) {
                if let artistSelectedIndex {
                    isLoadingData = true
                    Task {
                        imagesName = await TwitterDataReader.readImageData(artistId: artistsData[artistSelectedIndex].id) ?? []
                        isLoadingData = false
                    }
                } else {
                    imagesName = []
                }
            }
    }
    
    private func getImageURL(artistId: String, imageName: String) -> URL {
        return URL(filePath: "/Volumes/ACG/twitter").appendingPathComponent(artistId).appendingPathComponent(imageName)
    }
}


