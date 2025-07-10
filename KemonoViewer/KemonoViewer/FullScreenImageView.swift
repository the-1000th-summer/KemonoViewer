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

class PlayerViewModel: ObservableObject {
    @Published var avPlayer: AVPlayer?
    
    func loadFromUrl(url: URL) {
        avPlayer = AVPlayer(url: url)
    }
}

struct CustomPlayerView: View {
    var url : URL
    @StateObject private var playerViewModel = PlayerViewModel()

    var body: some View {
        ZStack {
            if let avPlayer = playerViewModel.avPlayer {
                VideoPlayer(player: avPlayer)
            }
        }.onAppear {
            playerViewModel.loadFromUrl(url: url)
        }
    }
}

struct FullScreenImageView: View {
    
    let imagePointerData: ImagePointerData
    
    @StateObject private var slideManager = SlideShowManager()

    @FocusState private var focused: Bool
    @State private var transform = Transform()
    @State private var isHoveringPathView = false
    
    @StateObject private var imagePointer = ImagePointer()
    @StateObject private var messageManager = StatusMessageManager()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let currentURL = imagePointer.currentImageURL {
                    if (UTType(filenameExtension: currentURL.pathExtension)?.conforms(to: .image) ?? false) {
                        if (UTType(filenameExtension: currentURL.pathExtension)?.conforms(to: .gif) ?? false) {
//                            GifImageView(imageURL: imagePointer.currentImageURL!)
                            KFAnimatedImage(source:
                                .provider(LocalFileImageDataProvider(fileURL: currentURL))
                            )
                            .configure { view in
                                view.imageScaling = .scaleProportionallyUpOrDown
                            }
//                            GIFImageView2(gifURL: imagePointer.currentImageURL!)
//                                .frame(minWidth: 10, minHeight: 10)
                            .resizableView(transform: $transform, messageManager: messageManager)
                            .scaledToFit()
                            .focusable()
                            .focused($focused)
                            .onAppear {
                                focused = true
                            }
                        } else {
                            AsyncImage(url: currentURL) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .resizableView(transform: $transform, messageManager: messageManager)
                                        .onChange(of: currentURL) {
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
                            .focusable()
                            .focused($focused)
                            .onAppear {
                                focused = true
                            }
                        }
                    } else if (UTType(filenameExtension: currentURL.pathExtension)?.conforms(to: .movie) ?? false) {
                        CustomPlayerView(url: currentURL)
                            .focusable()
                            .focused($focused)
                            .onAppear {
                                focused = true
                            }
                    } else {
                        VStack {
                            Image("custom.document.fill.badge.questionmark")
                                .font(.largeTitle)
                            Text("\(currentURL.lastPathComponent)\nNot an image file")
                        }
                        .focusable()
                        .focused($focused)
                        .onAppear {
                            focused = true
                        }
                    }
                } else {
                    Text("No attachments.")
                }
            }
            .contextMenu {
                ContextMenuView(manager: slideManager) {
                    showNextImage()
                }
            }
            // 保证视图扩展到窗口边缘，Text view在正常位置
            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .focusable()
//            .focused($focused)
//            .focusEffectDisabled()
            .onAppear {
                imagePointer.loadData(imagePointerData: imagePointerData)
                if let window = NSApplication.shared.keyWindow {
                    window.toggleFullScreen(nil)
                }
                focused = true
            }
            .onKeyPress("[", phases: [.down, .repeat]) { keyPress in
                if keyPress.phase == .down {
                    DispatchQueue.main.async {  // In order to eliminate the warning
                        showPreviousImage()
                        slideManager.restart()
                    }
                }
                return .handled
            }
            .onKeyPress("]", phases: [.down, .repeat]) { keyPress in
                if keyPress.phase == .down {
                    DispatchQueue.main.async {  // In order to eliminate the warning
                        showNextImage()
                        slideManager.restart()
                    }
                }
                return .handled
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
                    Spacer()
                    Button(action: {
                        showNextImage()
                        slideManager.restart()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.largeTitle)
                    }
                    .buttonStyle(PlainButtonStyle())
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
                    print(hovering)
                }
                .animation(.easeInOut, value: isHoveringPathView)
            }
        }
    }
    
//    private func getFileName(url: URL) -> String {
//        return url.lastPathComponent
//    }
    
    
    private func showNextImage() {
        let dirURLChanged = imagePointer.nextImage()
        if dirURLChanged, let currentPostDirURL = imagePointer.currentPostDirURL {
            messageManager.show(
                message: "下一个文件夹：\n" + currentPostDirURL.path(percentEncoded: false)
            )
        }
        if !dirURLChanged && imagePointer.isLastPost() {
            messageManager.show(
                message: "已经是最后一张图片"
            )
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

class SlideShowManager: ObservableObject {
    private var timer: Timer?
    @Published var currentInterval: TimeInterval = 0
    var timerAction: (() -> Void)?
    
    func start(interval: TimeInterval, action: @escaping () -> Void) {
        timerAction = action
        currentInterval = interval
        
        restart()
    }
    
    func restart() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: currentInterval,
            repeats: true
        ) { [weak self] _ in
            self?.timerAction?()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        currentInterval = 0
    }
    
    deinit {
        stop()
    }
}

struct ContextMenuView: View {
    @ObservedObject var manager: SlideShowManager
    let slideTimerAction: () -> Void
    private let timeIntervalList: [TimeInterval] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 60, 90]
    
    var body: some View {
        Menu("幻灯片放映") {
            Button(action: {
                manager.stop()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                        .tint(.primary.opacity(
                            manager.currentInterval == 0 ? 1 : 0
                        ))
                    Text("停止放映")
                }
            }
            
            ForEach(timeIntervalList, id: \.self) { timeIntervalInSecond in
                Button(action: {
                    manager.start(interval: timeIntervalInSecond) {
                        slideTimerAction()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                            .tint(.primary.opacity(
                                manager.currentInterval == timeIntervalInSecond ? 1 : 0
                            ))
                        Text("\(Int(timeIntervalInSecond))秒")
                    }
                }
            }
        }
    }
}
