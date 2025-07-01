//
//  GridItemView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct GridItemView: View {
    @Environment(\.openWindow) private var openWindow
    let size: Double
    let imageURL: URL
    
    var body: some View {
//        AsyncImage(url: imageURL) { image in
//            image
//                .resizable()
//                .scaledToFill()
//        } placeholder: {
//            ProgressView()
//        }
        AsyncImage(url: imageURL) { phase in
            if let image = phase.image {
                image // Displays the loaded image.
                    .resizable()
                    .scaledToFill()
            } else if phase.error != nil {
                Text(phase.error!.localizedDescription)
//                Color.red // Indicates an error.
            } else {
                ProgressView() // Acts as a placeholder.
            }
        }
        .frame(width: size, height: size)
        .id(imageURL)
        
    }
}

#Preview {
    GridItemView(size: 200, imageURL: URL(filePath: "/Volumes/ACG/kemono/5924557/[2019-05-12]罠にかかった秋月修正/1.jpe"))
}
