//
//  CustomPlayerView.swift
//  KemonoViewer
//
//  Created on 2025/7/17.
//

import SwiftUI
import AVKit

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

struct CustomVideoPlayer: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> CustomAVPlayerView {
        let view = CustomAVPlayerView()
        view.player = player
        return view
    }
    
    func updateNSView(_ nsView: CustomAVPlayerView, context: Context) {
        nsView.player = player
    }
}


