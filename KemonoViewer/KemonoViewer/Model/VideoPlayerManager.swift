//
//  VideoPlayerManager.swift
//  KemonoViewer
//
//  Created on 2025/7/10.
//

import Foundation
import AVKit
import Combine

class VideoPlayerManager: ObservableObject {
    @Published var avPlayer: AVPlayer?
    private var cancellable: AnyCancellable?
//    private var cancellable2: AnyCancellable?
    
    private var postPlayAction: (() -> Void)?
    
    private var timeInterval: TimeInterval = 0
    
    deinit {
        cancellable?.cancel()
        avPlayer?.pause()
    }
    
    func loadFromUrl(url: URL, timeInterval: TimeInterval, postPlayAction: (() -> Void)? = nil) {
        avPlayer?.pause()
        avPlayer?.replaceCurrentItem(with: nil)
        
        avPlayer = AVPlayer(url: url)
        self.timeInterval = timeInterval
        self.postPlayAction = postPlayAction
    }
    
    func setupPlaybackObserver() {
        
        guard let avPlayer else { return }
        
        cancellable = NotificationCenter.default.publisher(
            for: AVPlayerItem.didPlayToEndTimeNotification,
            object: avPlayer.currentItem
        )
        .sink { [weak self] _ in
            print("finished")
            self?.handlePlaybackEnded()
        }
    }
    
    private func handlePlaybackEnded() {
        print("播放完毕")
        
        self.postPlayAction?()

    }
    
    
    func play() {
        avPlayer?.play()
    }
    func pause() {
        avPlayer?.pause()
    }
    
    
}
