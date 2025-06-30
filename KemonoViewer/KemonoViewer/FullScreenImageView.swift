//
//  FullScreenImageView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct FullScreenImageView: View {
    
    let imagePointerData: ImagePointerData
    @StateObject private var imagePointer = ImagePointer()
    
    var body: some View {
        VStack {
            AsyncImage(url: imagePointer.currentImageURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
            Button("next") {
                imagePointer.nextImage()
            }
        }
        .onAppear {
            imagePointer.loadData(imagePointerData: imagePointerData)
            if let window = NSApplication.shared.keyWindow {
                window.toggleFullScreen(nil)
            }
            
        }
    
    }
}

//#Preview {
//    FullScreenImageView()
//}
