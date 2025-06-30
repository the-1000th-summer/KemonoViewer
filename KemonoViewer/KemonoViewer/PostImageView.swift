//
//  PostImageView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct PostImageView: View {
    private static let initialColumns = 3
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    @State private var imagesName = [String]()
    @State private var postDirPath: String? = nil
    var postSelectedId: Int64?
    
    var body: some View {
        ScrollView {
            if let postDirPath {
                LazyVGrid(columns: gridColumns) {
                    ForEach(imagesName, id: \.self) { imageName in
                        GeometryReader { geo in
                            GridItemView(size: geo.size.width, imageURL: URL(filePath: postDirPath).appendingPathComponent(imageName))
                        }
                        .cornerRadius(8.0)
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    Text("lack post dir path in database.")
                    Spacer()
                }
                
            }
        }
        .onChange(of: postSelectedId) {
            if let postSelectedId {
                let imageData = DataReader.readImageData(postId: postSelectedId)
                postDirPath = imageData.1
                imagesName = imageData.0 ?? []
            }
        }
    }
}

#Preview {
    PostImageView(postSelectedId: 5)
}
