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
        AsyncImage(url: imageURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            ProgressView()
        }
        .frame(width: size, height: size)
        
    }
}

#Preview {
    GridItemView(size: 200, imageURL: URL(filePath: "/Volumes/ACG/kemono/5924557/[2019-05-12]罠にかかった秋月修正/1.jpe"))
}
