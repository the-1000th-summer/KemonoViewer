//
//  Util.swift
//  KemonoViewer
//
//  Created on 2025/6/30.
//

import Foundation
import SQLite
import SwiftUI

class StatusMessageManager: ObservableObject {
    @Published var message: String = ""
    @Published var isVisible: Bool = false
    private var timer: Timer?
    
    func show(message: String, duration: TimeInterval = 1.0) {
        // 取消之前的计时器
        timer?.invalidate()
        
        // 更新消息并显示
        self.message = message
        withAnimation(.easeIn(duration: 0.2)) {
            isVisible = true
        }
        
        // 设置新的计时器
        timer = Timer.scheduledTimer(
            withTimeInterval: duration,
            repeats: false
        ) { [weak self] _ in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.isVisible = false
            }
        }
    }
    
    // 手动取消计时器（可选）
    func cancel() {
        timer?.invalidate()
        withAnimation {
            isVisible = false
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

