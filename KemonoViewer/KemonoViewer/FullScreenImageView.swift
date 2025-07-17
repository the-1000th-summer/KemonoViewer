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
    @State private var isHoveringPreviousButton = false
    @State private var isHoveringNextButton = false
    @State private var isHoveringSidebarButton = false
    
    @State private var fileNotFoundPresented = false
    
    @State private var showSidebar = false
    
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
    
    var body: some View {
        ZStack {
            HStack(spacing: .zero) {   // zero spacing for divider
                ZStack(alignment: .topTrailing) {
                    HSplitView {
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
                                VStack {
                                    Spacer()
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 50))
                                    Spacer()
                                }
                                .padding(20)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut("[", modifiers: .command)
                            .opacity(isHoveringPreviousButton ? 1 : 0)
                            .onHover { hovering in
                                isHoveringPreviousButton = hovering
                            }
                            .animation(.easeInOut, value: isHoveringPreviousButton)
                            
                            Spacer()
                            
                            Button(action: {
                                showNextImage()
                                slideManager.restart()
                            }) {
                                VStack {
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 50))
                                    Spacer()
                                }
                                .padding(20)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut("]", modifiers: .command)
                            .opacity(isHoveringNextButton ? 1 : 0)
                            .onHover { hovering in
                                isHoveringNextButton = hovering
                            }
                            .animation(.easeInOut, value: isHoveringNextButton)
                        }
                        Spacer()
                    }
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
                    .opacity(isHoveringPreviousButton ? 1 : 0)
                    .onHover { hovering in
                        isHoveringPreviousButton = hovering
                    }
                    .padding(20)
                    .animation(.easeInOut, value: isHoveringPreviousButton)
                }
                .background {
                    Color.black
                }
                if showSidebar {
                    Divider()
                    PostTextContentView(imagePointer: imagePointer)
                        .frame(width: 500)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 10)
//                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
//                        )
                        .transition(.move(edge: .trailing))
                        .zIndex(1)
                }
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
    
    private func localFileExists(at url: URL) -> Bool {
        guard url.isFileURL else { return false }
        
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: url.path)
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
        artistName: "Belko",
        artistService: "fanbox",
        artistKemonoId: "39123643",
        postsFolderName: ["[fanbox][2019-10-25]2019.10.25 オリジナル系原寸PNG+ラフ"],
        postsId: [2],
        currentPostImagesName: ["1.png"],
        currentPostIndex: 0,
        currentImageIndex: 0)
    )
}


