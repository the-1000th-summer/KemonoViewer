//
//  TwitterFullScreenImageView.swift
//  KemonoViewer
//
//  Created on 2025/7/18.
//

import SwiftUI

struct TwitterFullScreenImageView: View {
    var body: some View {
//        ZStack {
//            HStack(spacing: .zero) {   // zero spacing for divider
//                ZStack(alignment: .topTrailing) {
//                    HSplitView {
//                        if let currentURL = imagePointer.currentImageURL {
//                            mediaView(for: currentURL)
//                        } else {
//                            Text("No attachments.")
//                        }
//                    }
//                    .contextMenu {
//                        ContextMenuView(manager: slideManager, playerManager: playerManager) {
//                            if slideManager.getMovieCompleted() {
//                                showNextImage()
//                            }
//                        }
//                    }
//                    // 保证视图扩展到窗口边缘，Text view在正常位置
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .onAppear {
//                        imagePointer.loadData(imagePointerData: imagePointerData)
//                        if let window = NSApplication.shared.keyWindow {
//                            window.toggleFullScreen(nil)
//                        }
//                    }
//                }
//                
//            }
//        }
        Text("not implemented")
    }
}

#Preview {
    TwitterFullScreenImageView()
}
