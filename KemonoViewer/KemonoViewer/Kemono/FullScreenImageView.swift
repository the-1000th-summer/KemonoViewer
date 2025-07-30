//
//  FullScreenImageView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI
import AVKit
import Kingfisher
import UniformTypeIdentifiers
import Combine

struct ShowSidebarButtonView: View {
    @Binding var showSidebar: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showSidebar.toggle()
            }
        }) {
            Image(systemName: "sidebar.squares.right")
                .foregroundStyle(showSidebar ? .blue : .primary)
                .font(.system(size: 25))
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 50, height: 50)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(20)
        .hoverVisible()
    }
}

struct HoverOpacityModifier: ViewModifier {
    @State private var isHovering = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isHovering ? 1 : 0)
            .onHover { hovering in
                withAnimation(.easeInOut) {
                    isHovering = hovering
                }
            }
    }
}

// 扩展 View 提供便捷调用方式
extension View {
    func hoverVisible() -> some View {
        modifier(HoverOpacityModifier())
    }
}


struct PreviousButtonView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 50))
                .padding(.horizontal, 20)
                .padding(.vertical, 200)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .keyboardShortcut("[", modifiers: .command)
        .hoverVisible()
    }
}

struct NextButtonView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 50))
                .padding(.horizontal, 20)
                .padding(.vertical, 200)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .keyboardShortcut("]", modifiers: .command)
        .hoverVisible()
    }
}

struct ImagePathShowView: View {
    let pathText: String
    
    var body: some View {
        VStack {
            Spacer()
            Text(pathText)
            
            .padding(5)
            .frame(maxWidth: .infinity)
            .background(
                Rectangle()
                    .fill(Color.black.opacity(0.7))
            )
            .hoverVisible()
        }
    }
}

struct MessageView: View {
    @ObservedObject var messageManager: StatusMessageManager
    var body: some View {
        if messageManager.isVisible {
            Text(messageManager.message)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.7))
                )
                .foregroundColor(.white)
                .zIndex(1)   // 确保在顶层，保证在text消失时不会突然被图片覆盖
                .padding(.top, 100)
                .padding(.trailing, 100)
        }
    }
}

struct FullScreenImageView: View {
    
    let imagePointerData: ImagePointerData
    
    @StateObject private var imagePointer = KemonoImagePointer()
    
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
                    HSplitView {        // prevent image across views
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
                    PostTextContentView(imagePointer: imagePointer)
                        .frame(width: 500)
                        .transition(.move(edge: .trailing))
                        .zIndex(1)
                }
            }
            ImagePathShowView(pathText: "\(imagePointer.currentPostDirURL?.path(percentEncoded: false) ?? "" ) > \(imagePointer.currentImageURL?.lastPathComponent ?? "[no attachments]")")
        }
        .onDisappear {
            NotificationCenter.default.post(
                name: .kemonoFullScreenViewClosed,
                object: nil
            )
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
        if let currentImageURL = imagePointer.currentImageURL, (UTType(filenameExtension: currentImageURL.pathExtension)?.conforms(to: .movie) ?? false) || (UTType(filenameExtension: currentImageURL.pathExtension)?.conforms(to: .gif) ?? false) || currentImageURL.pathExtension == "ugoira" {
            slideManager.setMovieCompleted(completed: false)
            slideManager.pauseForMovie()
        } else {
            // the file is not media file, no need to wait loading data
            slideManager.setMovieCompleted(completed: true)
        }
    }
}

#Preview {
    FullScreenImageView(imagePointerData: ImagePointerData(
        artistsData: [KemonoArtist_show(
            name: "Belko",
            service: "fanbox",
            kemonoId: "39123643",
            hasNotViewed: false,
            id: 1
        )],
        postsFolderName: ["[fanbox][2019-10-25]2019.10.25 オリジナル系原寸PNG+ラフ"],
        postsId: [2],
        postsViewed: [false],
        currentPostImagesName: ["1.png"],
        currentArtistIndex: 0,
        currentPostIndex: 0,
        currentImageIndex: 0,
        postQueryConfig: KemonoPostQueryConfig()
    ))
}


