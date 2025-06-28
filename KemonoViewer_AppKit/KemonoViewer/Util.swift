//
//  Util.swift
//  KemonoViewer
//
//  Created on 2025/6/11.
//

import Foundation

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
