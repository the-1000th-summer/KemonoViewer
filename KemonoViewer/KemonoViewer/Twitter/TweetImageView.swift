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
    let sortItem: String
}

struct TweetImageView: View {
    @Environment(\.openWindow) private var openWindow
    private static let initialColumns = 3
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    @State private var isLoadingData: Bool = false
    @State private var imagesData = [TwitterImage_show]()
    
    @State private var scrollToTop = false
    @State private var scrollToBottom = false
    
    @Binding var artistsData: [TwitterArtist_show]
    @Binding var autoScrollToFirstNotViewedImage: Bool
    var artistSelectedIndex: Int?
    
    var queryConfig: TwitterImageQueryConfig
    
    private let oneImageViewedPub = NotificationCenter.default.publisher(for: .updateNewViewedTwitterImageUI)
    private let allViewedPub = NotificationCenter.default.publisher(for: .updateAllTwitterImageViewedStatus)
    private let fullScrViewClosedPub = NotificationCenter.default.publisher(for: .tweetFullScreenViewClosed)
    
    @ViewBuilder
    private func mainTweetImageView() -> some View {
        if isLoadingData {
            VStack {
                Spacer()
                LoadingDataView()
                Spacer()
            }
            
        } else {
            ZStack(alignment: .bottomTrailing) {
                ScrollViewReader { proxy in
                    ScrollView {
                        if let artistSelectedIndex {
                            if imagesData.isEmpty {
                                Text("No attachments in this post.")
                            } else {
                                Color.clear
                                    .frame(height: 0)
                                    .id("topAnchor")
                                LazyVGrid(columns: gridColumns) {
                                    ForEach(imagesData.indices, id: \.self) { imageIndex in
                                        GeometryReader { geo in
                                            Button(action: {
                                                updateDB_newViewedStatusImage(imageIndex: imageIndex, viewed: true)
                                                updateUI_newViewedStatusImage(imageIndex: imageIndex, viewed: true)
                                                let fsWindowData = TwitterImagePointerData(
                                                    artistsName: artistsData.map { $0.name },
                                                    artistsTwitterId: artistsData.map { $0.twitterId },
                                                    artistsId: artistsData.map { $0.id },
                                                    currentArtistImagesData: imagesData,
                                                    currentArtistIndex: artistSelectedIndex,
                                                    currentImageIndex: imageIndex,
                                                    imageQueryConfig: queryConfig
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
                                                    VStack {
                                                        Spacer()
                                                        Text(imagesData[imageIndex].sortItem)
                                                            .padding(5)
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                            .background(
                                                                Rectangle()
                                                                    .fill(Color.black.opacity(0.7))
                                                            )
                                                    }
                                                }
                                                .contentShape(Rectangle())
                                                .contextMenu {
                                                    Button("标记为未读") {
                                                        updateUI_newViewedStatusImage(imageIndex: imageIndex, viewed: false)
                                                        updateDB_newViewedStatusImage(imageIndex: imageIndex, viewed: false)
                                                    }
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .cornerRadius(8.0)
                                        .aspectRatio(1, contentMode: .fit)
                                        .id(Int(imageIndex))
                                    }
                                }
                                .onAppear {
                                    if autoScrollToFirstNotViewedImage {
                                        guard let firstNotViewedIndex: Int = imagesData.firstIndex(where: { !$0.viewed }) else { return }
                                        proxy.scrollTo(firstNotViewedIndex, anchor: .top)
                                    }
                                }
                                .onChange(of: scrollToTop) {
                                    proxy.scrollTo("topAnchor", anchor: .top)
                                }
                                .onChange(of: scrollToBottom) {
                                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                                }
                                Color.clear
                                    .frame(height: 0)
                                    .id("bottomAnchor")
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
                if artistSelectedIndex != nil {
                    ScrollToTopBottomButton(scrollToTop: $scrollToTop, scrollToBottom: $scrollToBottom)
                }
            }
        }
    }
    
    var body: some View {
        mainTweetImageView()
            .onChange(of: artistSelectedIndex) {
                reloadImagesData()
            }
            .onChange(of: queryConfig) {
                reloadImagesData()
            }
            .onReceive(oneImageViewedPub) { notification in
                guard let currentArtistIndexFromPointer = notification.userInfo?["currentArtistIndex"] as? Int, let viewedImageIndex = notification.userInfo?["viewedImageIndex"] as? Int else { return }
                // TweetImageView中选中的artist与全屏中浏览的artist可能不同
                if artistSelectedIndex == currentArtistIndexFromPointer {
                    updateUI_newViewedStatusImage(imageIndex: viewedImageIndex, viewed: true)
                }
            }
            .onReceive(allViewedPub) { notification in
                guard let doActionArtistIndex = notification.userInfo?["artistIndex"] as? Int else { return }
                if doActionArtistIndex == artistSelectedIndex {
                    reloadImagesData()
                }
            }
            .onReceive(fullScrViewClosedPub) { _ in
                if queryConfig.onlyShowNotViewedPost {
                    reloadImagesData()
                }
            }
            
        
        
    }
    
    private func updateUI_newViewedStatusImage(imageIndex: Int, viewed: Bool) {
        let originalImageData = imagesData[imageIndex]
        // prevent unnecessary view refreshing and database reading
        guard originalImageData.viewed != viewed else { return }
        
        imagesData[imageIndex] = TwitterImage_show(
            id: originalImageData.id,
            name: originalImageData.name,
            viewed: viewed,
            sortItem: originalImageData.sortItem
        )
        
        Task {
            await checkForArtistNotViewed()
        }
    }
    
    private func updateDB_newViewedStatusImage(imageIndex: Int, viewed: Bool) {
        Task {
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
    
    private func reloadImagesData() {
        if let artistSelectedIndex {
            isLoadingData = true
            Task {
                imagesData = await TwitterDataReader.readImageData_async(artistId: artistsData[artistSelectedIndex].id, queryConfig: queryConfig) ?? []
                isLoadingData = false
            }
        } else {
            imagesData = []
        }
    }
    
    private func getImageURL(artistId: String, imageName: String) -> URL {
        return URL(filePath: Constants.twitterBaseDir).appendingPathComponent(artistId).appendingPathComponent(imageName)
    }
}


