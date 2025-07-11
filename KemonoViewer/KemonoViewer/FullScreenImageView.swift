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

class CustomAVPlayerView: AVPlayerView {
    private var scrollMonitor: Any?
    
    // 仅拦截滚轮导致的进度条移动
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard scrollMonitor == nil, window != nil else { return }
        
        // 注册本地监视器，拦截所有滚轮事件
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] evt in
            guard let self = self, let win = self.window else {
                return evt
            }
            
            // 把事件坐标转换到当前 view
            let locationInWindow = evt.locationInWindow
            let pointInView = self.convert(locationInWindow, from: nil)
            
            // 如果滚轮事件落在视频视图区域内，就吞掉（返回 nil）
            if self.bounds.contains(pointInView) {
                return nil
            }
            // 否则照常处理
            return evt
        }
    }
}

// 2. 包装为 SwiftUI 视图
struct CustomVideoPlayer: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> CustomAVPlayerView {
        let view = CustomAVPlayerView()
        view.player = player
//        view.controlsStyle = .floating
        return view
    }
    
    func updateNSView(_ nsView: CustomAVPlayerView, context: Context) {
        nsView.player = player
    }
}


struct CustomPlayerView: View {
    var url: URL
    @ObservedObject var slideShowManager: SlideShowManager
    @ObservedObject var playerManager: VideoPlayerManager
    
    let postPlayAction: (() -> Void)
    
    var body: some View {
        ZStack {
            Color.clear        // 保证鼠标在视频范围内能正常缩放
            VStack {
                if let avPlayer = playerManager.avPlayer {
                    CustomVideoPlayer(player: avPlayer)
                        .onAppear {
                            slideShowManager.setMovieCompleted(completed: false)
                            playerManager.setupPlaybackObserver()
                            playerManager.play()
                        }
                        .onDisappear {
                            playerManager.pause()
                        }
                        .onChange(of: url) {
                            
                            playerManager.loadFromUrl(url: url, timeInterval: slideShowManager.currentInterval, postPlayAction: self.postPlayAction)
                            slideShowManager.setMovieCompleted(completed: false)
                            playerManager.setupPlaybackObserver()
                            playerManager.play()
                        }
                }
            }.onAppear {
                slideShowManager.pauseForMovie()
                playerManager.loadFromUrl(url: url, timeInterval: slideShowManager.currentInterval, postPlayAction: self.postPlayAction)
            }
        }
    }
}

struct FullScreenImageView: View {
    
    let imagePointerData: ImagePointerData
    
    @StateObject private var slideManager = SlideShowManager()
    @StateObject private var playerManager = VideoPlayerManager()
    
    @State private var transform = Transform()
    @State private var isHoveringPathView = false
    
    @StateObject private var imagePointer = ImagePointer()
    @StateObject private var messageManager = StatusMessageManager()
    
    @ViewBuilder
    private func mediaView(for mediaURL: URL) -> some View {
        if (UTType(filenameExtension: mediaURL.pathExtension)?.conforms(to: .image) ?? false) {
            if (UTType(filenameExtension: mediaURL.pathExtension)?.conforms(to: .gif) ?? false) {
                KFAnimatedImage(source:
                    .provider(LocalFileImageDataProvider(fileURL: mediaURL))
                )
                .configure { view in
                    view.imageScaling = .scaleProportionallyUpOrDown
                }
                .resizableView(transform: $transform, messageManager: messageManager)
                .scaledToFit()
            } else {
                AsyncImage(url: mediaURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .resizableView(transform: $transform, messageManager: messageManager)
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
            .resizableView(transform: $transform, messageManager: messageManager)
        } else {
            VStack {
                Image("custom.document.fill.badge.questionmark")
                    .font(.largeTitle)
                Text("\(mediaURL.lastPathComponent)\nNot an image file")
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                if let currentURL = imagePointer.currentImageURL {
                    mediaView(for: currentURL)
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
            
            if messageManager.isVisible {
                Text(messageManager.message)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.7))
                    )
                    .foregroundColor(.white)
//                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(1)   // 确保在顶层，保证在text消失时不会突然被图片覆盖
                    .padding(.top, 100)
                    .padding(.trailing, 100)
            }
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        showPreviousImage()
                        slideManager.restart()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.largeTitle)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut("[", modifiers: .command)
                    Spacer()
                    Button(action: {
                        showNextImage()
                        slideManager.restart()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.largeTitle)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut("]", modifiers: .command)
                }
                Spacer()
            }
            
            VStack {
                Spacer()
                Text(
                    "\(imagePointer.currentPostDirURL?.path(percentEncoded: false) ?? "" ) > \(imagePointer.currentImageURL?.lastPathComponent ?? "[no attachments]")"
                )
                .opacity(isHoveringPathView ? 1 : 0)
                .padding(5)
                .frame(maxWidth: .infinity)
                .background(
                    Rectangle()
                        .fill(Color.black.opacity(isHoveringPathView ? 0.7 : 0))
                )
                .onHover { hovering in
                    isHoveringPathView = hovering
                }
                .animation(.easeInOut, value: isHoveringPathView)
            }
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
        artistName: "5924557",
        postsFolderName: ["[2019-06-10]初月くぱぁ"],
        postsId: [6],
        currentPostImagesName: ["1.jpe"],
        currentPostIndex: 0,
        currentImageIndex: 0)
    )
}


