//
//  AniImagePlayerView.swift
//  KemonoViewer
//
//  Created on 2025/7/28.
//

import SwiftUI
import UniformTypeIdentifiers

struct AniImagePlayerView_noControl: View {
    @State private var frames: [Image] = []
    @State private var durations: [Double] = []
    @State private var currentFrameIndex = 0
    
    @State private var isLoadingImage = false
    
    @State private var durationCompensationStart: DispatchTime = DispatchTime.now()
    
    var inputFileURL: URL
    
    var body: some View {
        ZStack {
            if isLoadingImage {
                ProgressView()
            } else {
                if let currentImage = frames.isEmpty ? nil : frames[currentFrameIndex] {
                    currentImage
                        .resizable()
                        .scaledToFill()
                }
            }
        }
        .onAppear {
            isLoadingImage = true
            Task {
                let parseResult = await AniImageDecoder.parseAniImage(imageURL: inputFileURL)
                await MainActor.run {
                    (frames, durations) = parseResult
                    isLoadingImage = false
                    startPlayingWork()
                }
            }
        }
        .onChange(of: currentFrameIndex) {
            let durationCompensation = DispatchTime.now().uptimeNanoseconds - durationCompensationStart.uptimeNanoseconds
            let duration = durations[currentFrameIndex]
            DispatchQueue.main.asyncAfter(deadline: .now() + duration - Double(durationCompensation) / 1e9) {
                startPlayingWork()
            }
        }
    }
    
    private func startPlayingWork() {
        durationCompensationStart = DispatchTime.now()
        goToFrame(currentFrameIndex + 1)
    }
    
    private func goToFrame(_ index: Int) {
        if index < 0 {
            currentFrameIndex = durations.count + index
        } else {
            currentFrameIndex = index % durations.count
        }
    }
}

struct AniImagePlayerView_hasControl: View {
    @State private var frames: [Image] = []
    @State private var durations: [Double] = []
    @State private var currentFrameIndex = 0
    
    @State private var isLoadingImage = false
    
    @Binding var insideView: Bool
    @Binding var transform: Transform
    @ObservedObject var messageManager: StatusMessageManager
    
    var inputFileURL: URL
    
    var body: some View {
        ZStack {
            if isLoadingImage {
                ProgressView()
            } else {
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
        }
        .onAppear {
            isLoadingImage = true
            Task {
                let parseResult = await AniImageDecoder.parseAniImage(imageURL: inputFileURL)
                await MainActor.run {
                    (frames, durations) = parseResult
                    isLoadingImage = false
                }
            }
        }
    }
}

//#Preview {
//    AniImagePlayerView()
//}
