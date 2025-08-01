//
//  Util.swift
//  KemonoViewer
//
//  Created on 2025/6/30.
//

import Foundation
import SQLite
import SwiftyJSON
import ZIPFoundation
import UniformTypeIdentifiers
import SwiftUI


struct Constants {
    static var kemonoBaseDir: String {
        UserDefaults.standard.string(forKey: AppStorageKeys.kemonoBaseDir)!
    }
    static var twitterBaseDir: String {
        UserDefaults.standard.string(forKey: AppStorageKeys.twitterBaseDir)!
    }
    static var pixivBaseDir: String {
        UserDefaults.standard.string(forKey: AppStorageKeys.pixivBaseDir)!
    }
    static var kemonoDatabaseFilePath: String {
        UserDefaults.standard.string(forKey: AppStorageKeys.kemonoDatabaseFilePath)!
    }
    static var twitterDatabaseFilePath: String {
        UserDefaults.standard.string(forKey: AppStorageKeys.twitterDatabaseFilePath)!
    }
    static var pixivDatabaseFilePath: String {
        UserDefaults.standard.string(forKey: AppStorageKeys.pixivDatabaseFilePath)!
    }
    
    static let pixivValidEmojiNames: Set<String> = [
        "normal", "surprise", "serious", "heaven", "happy", "excited", "sing", "cry",
        "normal2", "shame2", "love2", "interesting2", "blush2", "fire2", "angry2", "shine2", "panic2",
        "normal3", "satisfaction3", "surprise3", "smile3", "shock3", "gaze3", "wink3", "happy3", "excited3", "love3",
        "normal4", "surprise4", "serious4", "love4", "shine4", "sweat4", "shame4", "sleep4",
        "heart", "teardrop", "star"
    ]
}
class WindowOpenStatusManager: ObservableObject {
    static let shared = WindowOpenStatusManager()
    
    @Published var kemonoMainOpened = false
    @Published var kemonoFsOpened = false
    
    @Published var twitterMainOpened = false
    @Published var twitterFsOpened = false
    
    @Published var pixivMainOpened = false
    @Published var pixivFsOpened = false
    
    var shouldDisableKemonoControl: Bool {
        kemonoMainOpened || kemonoFsOpened
    }
    var shouldDisableTwitterControl: Bool {
        twitterMainOpened || twitterFsOpened
    }
    var shouldDisablePixivControl: Bool {
        pixivMainOpened || pixivFsOpened
    }
}


class AniImageDecoder {
    static func getFirstImageDataFromUgoiraFile(from url: URL) -> Data? {
        guard let archive = try? Archive(url: url, accessMode: .read, pathEncoding: nil) else {
            print("无法读取压缩包")
            return nil
        }
            
        for entry in archive {
            if let fileExtension = entry.path.split(separator: ".").last, (UTType(filenameExtension: String(fileExtension))?.conforms(to: .image) ?? false) {
                var data = Data()
                if let _ = try? archive.extract(entry, consumer: { chunk in
                    data.append(chunk)
                }) {
                    return data
                }
            }
        }
        return nil
    }
    
    static func parseAniImage(imageURL: URL) async -> (images: [Image], durations: [Double]) {
        if imageURL.pathExtension == "gif" {
            if let data = try? Data(contentsOf: imageURL) {
                return await AniImageDecoder.decodeGIF(data: data)
            }
        }
        if imageURL.pathExtension == "ugoira" {
            guard let parseResult = try? await AniImageDecoder.parseUgoiraFile(from: imageURL) else {
                return ([], [])
            }
            return parseResult
        }
        return ([], [])
    }
    
    static func decodeGIF(data: Data) async -> (images: [Image], durations: [Double]) {
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
    
    static func parseUgoiraFile(from url: URL) async throws -> (images: [Image], durations: [Double]) {
        guard let archive = try? Archive(url: url, accessMode: .read, pathEncoding: nil) else {
            throw NSError(domain: "UgoiraParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法读取压缩包"])
        }
        
        var jsonData: Data?
        var imageFiles: [String: Data] = [:] // 文件名: 图片数据
        
        for entry in archive {
            if entry.path.lowercased().hasSuffix(".json") {
                // 读取JSON文件
                var data = Data()
                _ = try archive.extract(entry) { chunk in
                    data.append(chunk)
                }
                jsonData = data
            } else if let fileExtension = entry.path.split(separator: ".").last, (UTType(filenameExtension: String(fileExtension))?.conforms(to: .image) ?? false) {
                // 读取图片文件
                var data = Data()
                _ = try archive.extract(entry) { chunk in
                    data.append(chunk)
                }
                imageFiles[entry.path] = data
            }
        }
        
        guard let jsonData = jsonData else {
            throw NSError(domain: "UgoiraParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "JSON文件未找到"])
        }
        
        guard let jsonObj = try? JSON(data: jsonData) else {
            print("转换为Json对象失败")
            return ([], [])
        }
        
        var images = [Image]()
        var durations = [Double]()
        
        for frame in jsonObj["frames"] {
            guard let imageData = imageFiles[frame.1["file"].stringValue], let nsImage = NSImage(data: imageData) else {
                throw NSError(domain: "UgoiraParser", code: 3, userInfo: [NSLocalizedDescriptionKey: "图片加载失败: \(frame.1["file"])"])
            }
            
            images.append(Image(nsImage: nsImage))
            durations.append(Double(frame.1["delay"].intValue) / 1000.0) // 毫秒转秒
        }
        
        return (images, durations)
    }
}

class UtilFunc {
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
    
    static func findFileURL(inputDirURL: URL, fileNameWithoutExt: String) -> URL? {
        let fileManager = FileManager.default
        
        do {
            // 获取目录下所有文件URL
            let fileURLs = try fileManager.contentsOfDirectory(
                at: inputDirURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            let filesOnlyURLs = fileURLs.filter { !$0.hasDirectoryPath }
            let targetFilesURL = filesOnlyURLs.filter { $0.deletingPathExtension().lastPathComponent == fileNameWithoutExt }
            
            if targetFilesURL.isEmpty {
                return nil
            } else {
                if targetFilesURL.count > 1 {
                    print("warning: multiple avatar files, get first file as avatar.")
                }
                return targetFilesURL[0]
            }
        } catch {
            print("Error reading directory: \(error)")
            return nil
        }
    }
    
    static func configureBrowserHeaders(for request: inout URLRequest) {
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://www.google.com/", forHTTPHeaderField: "Referer")
        request.setValue("1", forHTTPHeaderField: "Upgrade-Insecure-Requests")
        request.setValue("?0", forHTTPHeaderField: "Sec-Fetch-Dest")
    }
    
    static func checkIfIsValidSQLiteFile(inputPath: String) -> Bool {
        do {
            let db = try Connection(inputPath, readonly: true)
            return true
        } catch {
            return false
        }
    }
    
}


