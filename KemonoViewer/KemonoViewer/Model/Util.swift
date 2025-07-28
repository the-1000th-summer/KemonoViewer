//
//  Util.swift
//  KemonoViewer
//
//  Created on 2025/6/30.
//

import Foundation
import SQLite
import SwiftUI

struct Constants {
    static let kemonoBaseDir = "/Volumes/ACG/kemono"
    static let twitterBaseDir = "/Volumes/ACG/twitter"
    static let pixivBaseDir = "/Volumes/ACG/pixiv"
    
    static let kemonoDatabaseFilePath = "/Volumes/imagesShown/images.sqlite3"
    
    static let pixivDatabaseFilePath = "/Volumes/imagesShown/pixiv.sqlite3"
}

class UtilFunc {
    static func decodeGIF(data: Data) -> (images: [Image], durations: [Double]) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return ([], []) }
        let frameCount = CGImageSourceGetCount(source)
        
        var images: [Image] = []
        var framesDuration: [Double] = []
        
        for i in 0..<frameCount {
            // 获取图像帧
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(Image(nsImage: NSImage(cgImage: cgImage, size: .zero)))
            }
            
            // 获取帧属性
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
               let gifDict = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                
                // 优先使用未修正的延迟时间（更准确）
                let duration: Double
                if let unclampedDelay = gifDict[kCGImagePropertyGIFUnclampedDelayTime] as? Double {
                    duration = unclampedDelay
                } else if let delay = gifDict[kCGImagePropertyGIFDelayTime] as? Double {
                    duration = delay
                } else {
                    // 默认值：0.1 秒（100ms）
                    duration = 0.1
                }
                
                // GIF 规范：最小延迟时间为 0.02 秒
                framesDuration.append(max(duration, 0.02))
            }
        }
        return (images, framesDuration)
    }
    
    static func getSubdirectoryNames(atURL directoryURL: URL) -> [String]? {
        let fileManager = FileManager.default
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

    static func getSubdirectoryNames(atPath path: String) -> [String]? {
        let directoryURL = URL(filePath: path)
        return getSubdirectoryNames(atURL: directoryURL)
    }

    static func localFileExists(at url: URL) -> Bool {
        guard url.isFileURL else { return false }
        
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: url.path)
    }
}


