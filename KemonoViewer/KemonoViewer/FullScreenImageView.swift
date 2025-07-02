//
//  FullScreenImageView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct FullScreenImageView: View {
    
    let imagePointerData: ImagePointerData
    
//    @State private var commandKeyPressed: Bool = false
    @FocusState private var focused: Bool
    
    @StateObject private var imagePointer = ImagePointer()
    @StateObject private var messageManager = StatusMessageManager()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                if imagePointer.currentImageURL != nil {
                    AsyncImage(url: imagePointer.currentImageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    
                } else {
                    Text("No attachments.")
                }
                HStack {
                    Button("Next") {
                        let changedDirURL = imagePointer.nextImage()
                        if let changedDirURL {
                            messageManager.show(
                                message: "下一个文件夹：\n" + changedDirURL.path(percentEncoded: false)
                            )
                        }
                    }
                    Button("Previous") {
                        let changedDirURL = imagePointer.previousImage()
                        if let changedDirURL {
                            messageManager.show(
                                message: "上一个文件夹：\n" + changedDirURL.path(percentEncoded: false)
                            )
                        }
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
                focused = true
            }
            
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
            .onKeyPress("[", phases: [.down, .repeat]) { keyPress in
                if keyPress.phase == .down {
                    DispatchQueue.main.async {  // In order to eliminate the warning
                        let changedDirURL = imagePointer.previousImage()
                        if let changedDirURL {
                            messageManager.show(
                                message: "上一个文件夹：\n" + changedDirURL.path(percentEncoded: false)
                            )
                        }
                    }
                }
                return .handled
            }
            .onKeyPress("]", phases: [.down, .repeat]) { keyPress in
                if keyPress.phase == .down {
                    DispatchQueue.main.async {  // In order to eliminate the warning
                        let changedDirURL = imagePointer.nextImage()
                        if let changedDirURL {
                            messageManager.show(
                                message: "下一个文件夹：\n" + changedDirURL.path(percentEncoded: false)
                            )
                        }
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
}

//#Preview {
//    FullScreenImageView()
//}
