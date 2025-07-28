//
//  PixivFullScreenImageView.swift
//  KemonoViewer
//
//  Created on 2025/7/26.
//

import SwiftUI

struct PixivFullScreenImageView: View {
    
    @StateObject private var imagePointer = PixivImagePointer()
    
    var body: some View {
        ZStack {
            HStack(spacing: .zero) {   // zero spacing for divider
                ZStack(alignment: .topTrailing) {
                    HSplitView {
//                        if let currentURL = imagePointer.currentImageURL {
//                            MediaView(
//                                mediaURL: currentURL,
//                                insideView: $insideView,
//                                messageManager: messageManager,
//                                slideManager: slideManager,
//                                playerManager: playerManager
//                            )
//                        } else {
//                            Text("No attachments.")
//                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PixivFullScreenImageView()
}
