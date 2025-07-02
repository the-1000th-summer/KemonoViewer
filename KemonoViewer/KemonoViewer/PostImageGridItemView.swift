//
//  PostImageGridItemView.swift
//  KemonoViewer
//
//  Created on 2025/7/2.
//

import SwiftUI
import Kingfisher

struct PostImageGridItemView: View {
    let size: Double
    let imageURL: URL
    
    var body: some View {
//        AsyncImage(url: imageURL) { phase in
//            if let image = phase.image {
//                image
//                    .resizable()
//                    .scaledToFill()
//            } else if phase.error != nil {
//                Text(phase.error!.localizedDescription)
//            } else {
//                ProgressView()  // Acts as a placeholder.
//            }
//        }
        KFImage(imageURL)
            .placeholder { ProgressView() }
            .cacheMemoryOnly(true)
            .memoryCacheExpiration(.expired) // no cache
            .diskCacheExpiration(.expired)   // no cache
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
    }
}

#Preview {
    PostImageGridItemView(size: 200, imageURL: URL(filePath: "/Volumes/ACG/kemono/5924557/[2019-05-12]罠にかかった秋月修正/1.jpe"))
}
