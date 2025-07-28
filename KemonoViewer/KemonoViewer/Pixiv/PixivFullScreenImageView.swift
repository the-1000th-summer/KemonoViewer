//
//  PixivFullScreenImageView.swift
//  KemonoViewer
//
//  Created on 2025/7/26.
//

import SwiftUI

struct PixivFullScreenImageView: View {
    
    let imagePointerData: PixivImagePointerData
    
    @StateObject private var imagePointer = PixivImagePointer()
    
    @StateObject private var messageManager = StatusMessageManager()
    @StateObject private var slideManager = SlideShowManager()
    @StateObject private var playerManager = VideoPlayerManager()
    
    @State private var insideView = false
    
    var body: some View {
        ZStack {
            HStack(spacing: .zero) {   // zero spacing for divider
                ZStack(alignment: .topTrailing) {
                    HSplitView {
                        if let currentURL = imagePointer.currentImageURL {
                            MediaView(
                                mediaURL: currentURL,
                                insideView: $insideView,
                                messageManager: messageManager,
                                slideManager: slideManager,
                                playerManager: playerManager
                            )
                        } else {
                            Text("No attachments.")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        imagePointer.loadData(imagePointerData: imagePointerData)
                        if let window = NSApplication.shared.keyWindow {
                            window.toggleFullScreen(nil)
                        }
                    }
                }
            }
        }
    }
}

//#Preview {
//    PixivFullScreenImageView()
//}
