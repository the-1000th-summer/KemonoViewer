//
//  FullScreenImageView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct FullScreenImageView: View {
    
    let imagePointerData: ImagePointerData
    
    @StateObject private var slideManager = SlideShowManager()

    @FocusState private var focused: Bool
    @State var transform = Transform()
    
    @StateObject private var imagePointer = ImagePointer()
    @StateObject private var messageManager = StatusMessageManager()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                if imagePointer.currentImageURL != nil {
                    AsyncImage(url: imagePointer.currentImageURL) { image in
                        image
                            .resizable()
                            .resizableView(transform: $transform)
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    
                } else {
                    Text("No attachments.")
                }
                HStack {
                    Button("Previous") {
                        showPreviousImage()
                        slideManager.restart()
                    }
                    Button("Next") {
                        showNextImage()
                        slideManager.restart()
                    }
                }
            }
            .contextMenu {
                ContextMenuView(manager: slideManager) {
                    showNextImage()
                }
            }
            // 保证视图扩展到窗口边缘，Text view在正常位置
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                imagePointer.loadData(imagePointerData: imagePointerData)
                if let window = NSApplication.shared.keyWindow {
                    window.toggleFullScreen(nil)
                }
                focused = true
            }
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
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
        }
    }
    
    private func showNextImage() {
        let changedDirURL = imagePointer.nextImage()
        if let changedDirURL {
            messageManager.show(
                message: "下一个文件夹：\n" + changedDirURL.path(percentEncoded: false)
            )
        }
    }
    
    private func showPreviousImage() {
        let changedDirURL = imagePointer.previousImage()
        if let changedDirURL {
            messageManager.show(
                message: "上一个文件夹：\n" + changedDirURL.path(percentEncoded: false)
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
