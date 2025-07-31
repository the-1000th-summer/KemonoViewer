//
//  PixivFullScreenImageView.swift
//  KemonoViewer
//
//  Created on 2025/7/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct PixivFullScreenImageView: View {
    
    let imagePointerData: PixivImagePointerData
    
    @StateObject private var imagePointer = PixivImagePointer()
    
    @StateObject private var messageManager = StatusMessageManager()
    @StateObject private var slideManager = SlideShowManager()
    @StateObject private var playerManager = VideoPlayerManager()
    
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
                            Text("No attachments.")
                        }
                    }
                    .contextMenu {
                        ContextMenuView(manager: slideManager, playerManager: playerManager) {
                            if slideManager.getMovieCompleted() {
                                showNextImage()
                            }
                        }
                    }
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
                    PixivTextContentView(imagePointer: imagePointer)
                        .frame(width: 500)
                        .transition(.move(edge: .trailing))
                        .zIndex(1)
                        .background(Color(red: 29.0/255.0, green: 29.0/255.0, blue: 29.0/255.0))
                }
            }
            ImagePathShowView(pathText: "\(imagePointer.currentPostDirURL?.path(percentEncoded: false) ?? "" ) > \(imagePointer.currentImageURL?.lastPathComponent ?? "[no attachments]")")
        }
    }
    
    private func showNextImage() {
        let dirURLChanged = imagePointer.nextImage()
        if dirURLChanged, let currentPostDirURL = imagePointer.currentPostDirURL {
            messageManager.show(
                message: "下一个文件夹：\n" + currentPostDirURL.path(percentEncoded: false)
            )
        }
        if !dirURLChanged && imagePointer.isLastPost() {
            messageManager.show(message: "已经是最后一张图片")
        } else {
            setMovieCompleted()
        }
    }
    
    private func showPreviousImage() {
        let dirURLChanged = imagePointer.previousImage()
        if dirURLChanged, let currentPostDirURL = imagePointer.currentPostDirURL {
            messageManager.show(
                message: "上一个文件夹：\n" + currentPostDirURL.path(percentEncoded: false)
            )
        }
        if !dirURLChanged && imagePointer.isFirstPost() {
            messageManager.show(
                message: "已经是第一张图片"
            )
        } else {
            setMovieCompleted()
        }
    }
    
    private func setMovieCompleted() {
        if let currentImageURL = imagePointer.currentImageURL, (UTType(filenameExtension: currentImageURL.pathExtension)?.conforms(to: .movie) ?? false) || (UTType(filenameExtension: currentImageURL.pathExtension)?.conforms(to: .image) ?? false) || currentImageURL.pathExtension == "ugoira" {
            slideManager.setMovieCompleted(completed: false)
            slideManager.pauseForMovie()
        } else {
            slideManager.setMovieCompleted(completed: true)
        }
    }
    
}

//#Preview {
//    PixivFullScreenImageView()
//}
