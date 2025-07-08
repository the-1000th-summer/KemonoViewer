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

func getSubdirectoryNames(atPath path: String) -> [String]? {
    let fileManager = FileManager.default
    let directoryURL = URL(filePath: path)
    
    do {
        // 获取目录下所有内容（文件和文件夹）
        let contents = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles] // 可选：跳过隐藏文件
        ).filter(\.hasDirectoryPath)
        
        // 筛选出文件夹并返回名称
        return contents.compactMap { url in
            return url.lastPathComponent
        }
    } catch {
        print("获取目录失败: \(error.localizedDescription)")
        return nil
    }
}
