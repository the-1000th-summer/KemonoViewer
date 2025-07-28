//
//  PixivPostImageView.swift
//  KemonoViewer
//
//  Created on 2025/7/25.
//

import SwiftUI
import ImageIO




struct PixivPostImageView: View {
    @Environment(\.openWindow) private var openWindow
    private static let initialColumns = 3
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    @State private var imagesName = [String]()
    @State private var isLoadingData: Bool = false

    @Binding var artistsData: [PixivArtist_show]
    @Binding var postsData: [PixivPost_show]
    
    var artistSelectedIndex: Int?
    var postSelectedIndex: Int?
    
    var postQueryConfig: PixivPostQueryConfig
    
    @ViewBuilder
    private func mainPostImageView() -> some View {
        if isLoadingData {
            LoadingDataView()
        } else {
            ScrollView {
                if let artistSelectedIndex, let postSelectedIndex {
                    if imagesName.isEmpty {
                        Text("No images in this post.")
                    } else {
                        LazyVGrid(columns: gridColumns) {
                            ForEach(imagesName.indices, id: \.self) { imageIndex in
                                GeometryReader { geo in
                                    Button(action: {
                                        let fsWindowData = PixivImagePointerData(
                                            artistsData: artistsData,
                                            postsData: postsData,
                                            currentPostImagesName: imagesName,
                                            currentArtistIndex: artistSelectedIndex,
                                            currentPostIndex: postSelectedIndex,
                                            currentImageIndex: imageIndex,
                                            postQueryConfig: postQueryConfig
                                        )
                                        openWindow(id: "pixivFsViewer", value: fsWindowData)
                                    }) {
                                        PostImageGridItemView(
                                            size: geo.size.width,
                                            imageURL: getImageURL(artistIndex: artistSelectedIndex, postIndex: postSelectedIndex, imageIndex: imageIndex),
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
                }
            }
        }
    }
    
    var body: some View {
        mainPostImageView()
            .onChange(of: postSelectedIndex) {
                if let postSelectedIndex {
                    isLoadingData = true
                    Task {
                        let readResult = await PixivDataReader.readImageData_async(postId: postsData[postSelectedIndex].id)
                        await MainActor.run {
                            imagesName = readResult ?? []
                            isLoadingData = false
                        }
                    }
                }
            }
    }
    
    private func getImageURL(artistIndex: Int, postIndex: Int, imageIndex: Int) -> URL {
        return URL(filePath: Constants.pixivBaseDir).appendingPathComponent(artistsData[artistIndex].folderName).appendingPathComponent(postsData[postIndex].folderName).appendingPathComponent(imagesName[imageIndex])
    }
}

//#Preview {
//    PixivPostImageView()
//}
