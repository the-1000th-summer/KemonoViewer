//
//  TweetImageView.swift
//  KemonoViewer
//
//  Created on 2025/7/18.
//

import SwiftUI

struct TwitterImage_show: Hashable, Codable {
    let id: Int64
    let name: String
    let viewed: Bool
}

struct TweetImageView: View {
    @Environment(\.openWindow) private var openWindow
    private static let initialColumns = 3
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    @State private var isLoadingData: Bool = false
    @State private var imagesData = [TwitterImage_show]()
    
    @Binding var artistsData: [TwitterArtist_show]
    var artistSelectedIndex: Int?
    
    private let oneImageViewedPub = NotificationCenter.default.publisher(for: .updateNewViewedTwitterImageData)
    private let allViewedPub = NotificationCenter.default.publisher(for: .updateAllTwitterImageViewedStatus)
    
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
                    if imagesData.isEmpty {
                        Text("No attachments in this post.")
                    } else {
                        LazyVGrid(columns: gridColumns) {
                            ForEach(imagesData.indices, id: \.self) { imageIndex in
                                GeometryReader { geo in
                                    Button(action: {
                                        newViewedStatusImage(imageIndex: imageIndex, viewed: true)
                                        let fsWindowData = TwitterImagePointerData(
                                            artistsName: artistsData.map { $0.name },
                                            artistsTwitterId: artistsData.map { $0.twitterId },
                                            artistsId: artistsData.map { $0.id },
                                            currentArtistImagesData: imagesData,
                                            currentArtistIndex: artistSelectedIndex,
                                            currentImageIndex: imageIndex
                                        )
                                        openWindow(id: "twitterFsViewer", value: fsWindowData)
                                    }) {
                                        ZStack(alignment: .topTrailing) {
                                            PostImageGridItemView(
                                                size: geo.size.width,
                                                imageURL: getImageURL(artistId: artistsData[artistSelectedIndex].twitterId, imageName: imagesData[imageIndex].name),
                                            )
                                            Image(systemName: "circlebadge.fill")
                                                .padding(.top, 2)
                                                .padding(.trailing, 2)
                                                .foregroundStyle(.blue)
                                                .opacity(imagesData[imageIndex].viewed ? 0 : 1)
                                        }
                                        .contentShape(Rectangle())
                                        .contextMenu {
                                            Button("标记为未读") {
                                                newViewedStatusImage(imageIndex: imageIndex, viewed: false)
                                            }
                                        }
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
                        imagesData = await TwitterDataReader.readImageData(artistId: artistsData[artistSelectedIndex].id) ?? []
                        isLoadingData = false
                    }
                } else {
                    imagesData = []
                }
            }
            .onReceive(oneImageViewedPub) { notification in
                guard let viewedImageIndex = notification.userInfo?["viewedImageIndex"] as? Int else { return }
                newViewedStatusImage(imageIndex: viewedImageIndex, viewed: true)
            }
            .onReceive(allViewedPub) { notification in
                Task {
                    await refreshImagesData()
                }
            }
    }
    
    private func newViewedStatusImage(imageIndex: Int, viewed: Bool) {
        let originalImageData = imagesData[imageIndex]
        // prevent unnecessary view refreshing and database reading
        guard originalImageData.viewed != viewed else { return }
        
        imagesData[imageIndex] = TwitterImage_show(
            id: originalImageData.id,
            name: originalImageData.name,
            viewed: viewed
        )
        
        Task {
            await checkForArtistNotViewed()
            await TwitterDatabaseManager.shared.tagImage(imageId: imagesData[imageIndex].id, viewed: viewed)
        }
    }
    
    private func checkForArtistNotViewed() async {
        let artist_hasNotViewed = artistsData[artistSelectedIndex!].hasNotViewed
        let images_hasNotViewed = imagesData.contains { !$0.viewed }
        if artist_hasNotViewed != images_hasNotViewed {
            refreshArtistData(artistIndex: artistSelectedIndex!, hasNotViewed: images_hasNotViewed)
        }
    }
    
    private func refreshArtistData(artistIndex: Int, hasNotViewed: Bool) {
        let artistData = artistsData[artistIndex]
        artistsData[artistIndex] = TwitterArtist_show(
            name: artistData.name,
            twitterId: artistData.twitterId,
            hasNotViewed: hasNotViewed,
            id: artistData.id,
        )
    }
    
    private func refreshImagesData() async {
        if let artistSelectedIndex {
            imagesData = await TwitterDataReader.readImageData(artistId: artistsData[artistSelectedIndex].id) ?? []
        } else {
            imagesData = []
        }
    }
    
    private func getImageURL(artistId: String, imageName: String) -> URL {
        return URL(filePath: Constants.twitterBaseDir).appendingPathComponent(artistId).appendingPathComponent(imageName)
    }
}


