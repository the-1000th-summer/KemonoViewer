//
//  PostImageView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct PostImageView: View {
    @Environment(\.openWindow) private var openWindow
    private static let initialColumns = 3
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    @State private var imagesName = [String]()
    @State private var postDirPath: String? = nil
    @State private var isLoadingData: Bool = false
    
    @Binding var postsData: [Post_show]
//    let artistData: Artist_show
    @Binding var artistsData: [Artist_show]
    @Binding var artistSelectedIndex: Int?
    
    var postSelectedIndex: Int?
    
    @ViewBuilder
    private func mainPostImageView() -> some View {
        if isLoadingData {
            LoadingDataView()
        } else {
            ScrollView {
                if let postDirPath {
                    if imagesName.isEmpty {
                        Text("No attachments in this post.")
                    } else {
                        LazyVGrid(columns: gridColumns) {
                            ForEach(imagesName.indices, id: \.self) { imageIndex in
                                GeometryReader { geo in
                                    Button(action: {
                                        let fsWindowData = ImagePointerData(
                                            artistsData: artistsData,
                                            postsFolderName: postsData.map { $0.folderName },
                                            postsId: postsData.map { $0.id },
                                            currentPostImagesName: imagesName,
                                            currentArtistIndex: artistSelectedIndex!,
                                            currentPostIndex: postSelectedIndex!,
                                            currentImageIndex: imageIndex
                                        )
                                        openWindow(id: "fsViewer", value: fsWindowData)
                                    }) {
                                        PostImageGridItemView(
                                            size: geo.size.width,
                                            imageURL: URL(filePath: postDirPath).appendingPathComponent(imagesName[imageIndex]),
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
                        Text("Select post to show image.")
                        Spacer()
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
                    let imageData = await DataReader.readImageData(postId: postsData[postSelectedIndex].id)
                    imagesName = imageData.0 ?? []
                    postDirPath = imageData.1
                    isLoadingData = false
                }
            } else {
                imagesName = []
                postDirPath = nil
            }
        }
    }
}

//#Preview {
//    PostImageView(postSelectedin
//}
