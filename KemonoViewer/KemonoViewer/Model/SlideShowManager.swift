//
//  SlideShowManager.swift
//  KemonoViewer
//
//  Created on 2025/7/11.
//

import SwiftUI

class SlideShowManager: ObservableObject {
    private var timer: Timer?
    @Published var currentInterval: TimeInterval = 0
    private var movieCompleted = true
    var timerAction: (() -> Void)?
    
    func setMovieCompleted(completed: Bool) {
        movieCompleted = completed
    }
    func getMovieCompleted() -> Bool {
        return movieCompleted
    }
    
    func setIntervalAndAction(interval: TimeInterval, action: @escaping () -> Void) {
        currentInterval = interval
        timerAction = action
    }
    
    func start(interval: TimeInterval, action: @escaping () -> Void) {
        setIntervalAndAction(interval: interval, action: action)
        
        restart()
    }
    
    // for start() and pauseForMovie()
    func restart() {
        guard currentInterval > 0 else { return }
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
        timerAction = nil
        currentInterval = 0
    }
    
    func pauseForMovie() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stop()
    }
}

