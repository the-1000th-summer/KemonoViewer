//
//  AniImageControlView.swift
//  KemonoViewer
//
//  Created on 2025/7/27.
//

import SwiftUI

struct AniImageControlView: View {
    @Binding var currentFrameIndex: Int
    @State private var sliderValue: Double = 1.0
    @State private var durationCompensationStart: DispatchTime = DispatchTime.now()
    @State private var autoPlay = true
    @State private var isEditingSlider = false
    
    var durations: [Double]
    
    @State private var startPlayingWorkItem: DispatchWorkItem?
    let workFallenBack = DispatchWorkItem(block: {})
    
    let aniImageFinishedAction: () -> Void
    
    @ViewBuilder
    private func controlButton(imageSystemName: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            autoPlay = false
            startPlayingWorkItem?.cancel()
            startPlayingWorkItem = nil
            action()
        }) {
            Image(systemName: imageSystemName)
                .padding(5)
                .contentShape(Rectangle())
        }
    }
    
    var body: some View {
        VStack {
            Text("\( isEditingSlider ? Int(sliderValue) : (currentFrameIndex + 1))/\(durations.count)")
            Slider(value: $sliderValue, in: 1...Double(durations.count)) { editing in
                isEditingSlider = editing
                if !editing {
                    currentFrameIndex = Int(sliderValue) - 1
                }
            }
            .frame(maxWidth: 150)
            HStack {
                controlButton(imageSystemName: "arrow.left.to.line") {
                    goToFrame(0)
                }
                controlButton(imageSystemName: "arrow.left") {
                    goToFrame(currentFrameIndex - 1)
                }
                controlButton(imageSystemName: "arrow.right") {
                    goToFrame(currentFrameIndex + 1)
                }
                controlButton(imageSystemName: "arrow.right.to.line") {
                    goToFrame(durations.count - 1)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Toggle(isOn: $autoPlay) {
                Text("自动播放")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
        )
        .hoverVisible()
        .onAppear {
            startPlayingWorkItem = DispatchWorkItem(block: {
                startPlayingWork()
            })
            if autoPlay {
                startPlayingWork()
            }
        }
        .onChange(of: currentFrameIndex) {
            if !isEditingSlider {
                sliderValue = Double(currentFrameIndex) + 1
            }
            if autoPlay {
                let durationCompensation = DispatchTime.now().uptimeNanoseconds - durationCompensationStart.uptimeNanoseconds
                let duration = durations[currentFrameIndex]
                DispatchQueue.main.asyncAfter(deadline: .now() + duration - Double(durationCompensation) / 1e9, execute: startPlayingWorkItem ?? workFallenBack)
            }
        }
        .onChange(of: autoPlay) {
            if autoPlay {
                startPlayingWorkItem = DispatchWorkItem(block: {
                    startPlayingWork()
                })
                startPlayingWork()
            }
        }
    }
    
    private func startPlayingWork() {
        guard !durations.isEmpty else { return }
        durationCompensationStart = DispatchTime.now()
        goToFrame(currentFrameIndex + 1)
    }
    
    private func goToFrame(_ index: Int) {
        if index < 0 {
            currentFrameIndex = durations.count + index
        } else {
            currentFrameIndex = index % durations.count
            
            if index >= durations.count {
                aniImageFinishedAction()
            }
        }
    }
}

#Preview {
    AniImageControlView(currentFrameIndex: .constant(0), durations: Array(repeating: 0.2, count: 50)) {}
}
