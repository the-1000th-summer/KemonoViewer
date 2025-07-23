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

struct MediaView: View {
    
    let mediaURL: URL
    @State private var transform = Transform()
    @State private var fileNotFoundPresented = false
    
    @Binding var insideView: Bool
    
    @ObservedObject var messageManager: StatusMessageManager
    @ObservedObject var slideManager: SlideShowManager
    @ObservedObject var playerManager: VideoPlayerManager
    
    var body: some View {
        if (UTType(filenameExtension: mediaURL.pathExtension)?.conforms(to: .image) ?? false) {
            if (UTType(filenameExtension: mediaURL.pathExtension)?.conforms(to: .gif) ?? false) {
                KFAnimatedImage(source:
                    .provider(LocalFileImageDataProvider(fileURL: mediaURL))
                )
                .configure { view in
                    view.imageScaling = .scaleProportionallyUpOrDown
                }
                .resizableView(insideView: $insideView, transform: $transform, messageManager: messageManager)
                .scaledToFit()
            } else {
                AsyncImage(url: mediaURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .resizableView(insideView: $insideView, transform: $transform, messageManager: messageManager)
                            .onChange(of: mediaURL) {
                                withAnimation(.easeIn(duration: 0.2)) {
                                    transform = Transform()
                                }
                            }
                    } else if phase.error != nil {
                        VStack {
                            Image(systemName: "photo.badge.exclamationmark")
                            Text("Error: " + phase.error!.localizedDescription)
                        }
                        .font(.largeTitle)
                    } else {
                        ProgressView()  // Acts as a placeholder.
                    }
                }
            }
        } else if (UTType(filenameExtension: mediaURL.pathExtension)?.conforms(to: .movie) ?? false) {
            CustomPlayerView(url: mediaURL, slideShowManager: slideManager, playerManager: playerManager) {
                slideManager.setMovieCompleted(completed: true)
                slideManager.restart()
            }
            .resizableView(insideView: $insideView, transform: $transform, messageManager: messageManager)
        } else {
            VStack {
                Image("custom.document.fill.badge.questionmark")
                    .font(.largeTitle)
                Text("\(mediaURL.lastPathComponent)\nNot an image file")
                Button("Show in Finder") {
                    if localFileExists(at: mediaURL) {
                        NSWorkspace.shared.activateFileViewerSelecting([mediaURL])
                    } else {
                        fileNotFoundPresented = true
                    }
                }.popover(isPresented: $fileNotFoundPresented, arrowEdge: .bottom) {
                    Text("File not found in local filesystem.")
                        .padding()
                }
            }
        }
    }
}

struct FullScreenImageView: View {
    
    let imagePointerData: ImagePointerData
    
    @StateObject private var imagePointer = KemonoImagePointer()
    
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
        if let currentImageURL = imagePointer.currentImageURL, (UTType(filenameExtension: currentImageURL.pathExtension)?.conforms(to: .movie) ?? false) {
            slideManager.setMovieCompleted(completed: false)
            slideManager.pauseForMovie()
        } else {
            slideManager.setMovieCompleted(completed: true)
        }
    }
}

#Preview {
    FullScreenImageView(imagePointerData: ImagePointerData(
        artistsData: [Artist_show(
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
        postQueryConfig: PostQueryConfig()
    ))
}


