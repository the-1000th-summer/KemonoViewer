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
    
    static let kemonoDatabaseFilePath = "/Volumes/imagesShown/images.sqlite3"
    
    static let pixivDatabaseFilePath = "/Volumes/imagesShown/pixiv.sqlite3"
}



func getSubdirectoryNames(atURL directoryURL: URL) -> [String]? {
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

func getSubdirectoryNames(atPath path: String) -> [String]? {
    let directoryURL = URL(filePath: path)
    return getSubdirectoryNames(atURL: directoryURL)
}

func localFileExists(at url: URL) -> Bool {
    guard url.isFileURL else { return false }
    
    let fileManager = FileManager.default
    return fileManager.fileExists(atPath: url.path)
}
