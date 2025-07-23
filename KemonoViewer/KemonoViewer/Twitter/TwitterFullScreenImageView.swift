//
//  TwitterFullScreenImageView.swift
//  KemonoViewer
//
//  Created on 2025/7/18.
//

import SwiftUI
import UniformTypeIdentifiers

struct TwitterFullScreenImageView: View {
    
    let imagePointerData: TwitterImagePointerData
    
    @StateObject private var imagePointer = TwitterImagePointer()
    
    @StateObject private var slideManager = SlideShowManager()
    @StateObject private var playerManager = VideoPlayerManager()
    @StateObject private var messageManager = StatusMessageManager()
    
    @State private var showSidebar = false
    @State private var insideView = false
    
    @ViewBuilder
    private func changeImageButtonView() -> some View {
        VStack {
            Spacer()
            HStack {
                PreviousButtonView {
                    showPreviousImage()
                    slideManager.restart()
                }
                Spacer()
                NextButtonView {
                    showNextImage()
                    slideManager.restart()
                }
                
            }
            Spacer()
        }
    }
    
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
                            Text(imagePointerData.imageQueryConfig.onlyShowNotViewedPost ? "No new image in this artist." : "No image in this artist.")
                        }
                    }
                    .contextMenu {
                        ContextMenuView(manager: slideManager, playerManager: playerManager) {
                            if slideManager.getMovieCompleted() {
                                showNextImage()
                            }
                        }
                    }
                    // 保证视图扩展到窗口边缘，Text view在正常位置
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        imagePointer.loadData(imagePointerData: imagePointerData)
                        if let window = NSApplication.shared.keyWindow {
                            window.toggleFullScreen(nil)
                        }
                    }
                    MessageView(messageManager: messageManager)
                    changeImageButtonView()
                    ShowSidebarButtonView(showSidebar: $showSidebar)
                }
                .onHover { hovering in
                    insideView = hovering
                }
                .background {
                    Color.black
                }
                if showSidebar {
                    Divider()
                    TweetTextContentView(imagePointer: imagePointer)
                        .frame(width: 300)
                        .transition(.move(edge: .trailing))
                        .zIndex(1)
                }
            }
            ImagePathShowView(pathText: "\(imagePointer.currentArtistDirURL?.path(percentEncoded: false) ?? "" ) > \(imagePointer.currentImageURL?.lastPathComponent ?? "[no attachments]")")
        }
        .onDisappear {
            NotificationCenter.default.post(
                name: .tweetFullScreenViewClosed,
                object: nil
            )
        }
    }
    
    private func showNextImage() {
        let artistURLChanged = imagePointer.nextImage()
        if artistURLChanged, let currentArtistDirURL = imagePointer.currentArtistDirURL {
            messageManager.show(
                message: "下一个用户：\n" + currentArtistDirURL.path(percentEncoded: false)
            )
        }
        if !artistURLChanged && imagePointer.isLastPost() {
            messageManager.show(message: "已经是最后一张图片")
        } else {
            setMovieCompleted()
        }
    }
    
    private func showPreviousImage() {
        let artistURLChanged = imagePointer.previousImage()
        if artistURLChanged, let currentArtistDirURL = imagePointer.currentArtistDirURL {
            messageManager.show(
                message: "上一个用户：\n" + currentArtistDirURL.path(percentEncoded: false)
            )
        }
        if !artistURLChanged && imagePointer.isFirstPost() {
            messageManager.show(
                message: "已经是第一张图片"
            )
        } else {
            setMovieCompleted()
        }
    }
    
    private func setMovieCompleted() {
        if let currentImageURL = imagePointer.currentImageURL, (UTType(filenameExtension: currentImageURL.pathExtension)?.conforms(to: .movie) ?? false) {
            slideManager.setMovieCompleted(completed: false)
            slideManager.pauseForMovie()
        } else {
            slideManager.setMovieCompleted(completed: true)
        }
    }
}

//#Preview {
//    TwitterFullScreenImageView()
//}
