//
//  AniImagePlayerView.swift
//  KemonoViewer
//
//  Created on 2025/7/28.
//

import SwiftUI

struct AniImagePlayerView: View {
    @State private var frames: [Image] = []
    @State private var durations: [Double] = []
    @State private var currentFrameIndex = 0
    
    @Binding var insideView: Bool
    @Binding var transform: Transform
    @ObservedObject var messageManager: StatusMessageManager
    
    var gifURL: URL
    
    var body: some View {
            
        ZStack {
            if let currentImage = frames.isEmpty ? nil : frames[currentFrameIndex] {
                currentImage
                    .resizable()
                    .scaledToFit()
                    .resizableView(insideView: $insideView, transform: $transform, messageManager: messageManager)
                GeometryReader { geometry in
                    AniImageControlView(currentFrameIndex: $currentFrameIndex, durations: durations)
                    .position(
                        x: 100,
                        y: geometry.size.height - 100
                    )
                }
            }
        }
        
        .task {
            // 加载示例 GIF（实际应用中替换为你的 GIF 数据）
            if let data = try? Data(contentsOf: gifURL) {
                (frames, durations) = UtilFunc.decodeGIF(data: data)
            }
        }
        
    }
    
}

//#Preview {
//    AniImagePlayerView()
//}
