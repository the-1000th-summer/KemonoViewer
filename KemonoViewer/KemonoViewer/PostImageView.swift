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
    
    @Binding var postsData: [Post_show]
    @Binding var artistSelectedData: Artist_show?
    
    var postSelectedIndex: Int?
    
    var body: some View {
        ScrollView {
            if let postDirPath {
                if imagesName.isEmpty {
                    Text("No image in this post.")
                } else {
                    LazyVGrid(columns: gridColumns) {
                        ForEach(imagesName.indices, id: \.self) { imageIndex in
                            GeometryReader { geo in
                                Button(action: {
                                    let fsWindowData = ImagePointerData(
                                        artistName: artistSelectedData!.name,
                                        postsFolderName: postsData.map { $0.folderName },
                                        postsId: postsData.map { $0.id },
                                        currentPostImagesName: imagesName,
                                        currentPostIndex: postSelectedIndex!,
                                        currentImageIndex: imageIndex
                                    )
                                    openWindow(id: "fsViewer", value: fsWindowData)
                                }) {
                                    PostImageGridItemView(
                                        size: geo.size.width,
                                        imageURL: URL(filePath: postDirPath).appendingPathComponent(imagesName[imageIndex]),
                                    )
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
        .onChange(of: postSelectedIndex) {
            if let postSelectedIndex {
                let imageData = DataReader.readImageData(postId: postsData[postSelectedIndex].id)
                imagesName = imageData.0 ?? []
                postDirPath = imageData.1
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
