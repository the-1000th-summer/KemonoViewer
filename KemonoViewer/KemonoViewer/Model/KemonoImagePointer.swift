//
//  ImagePointer.swift
//  KemonoViewer
//
//  Created on 2025/7/19.
//

import SwiftUI
import SQLite

struct ImagePointerData: Hashable, Codable {
    var id = UUID()
    let artistsData: [Artist_show]
    let postsFolderName: [String]
    let postsId: [Int64]
    let currentPostImagesName: [String]
    
    let currentArtistIndex: Int
    let currentPostIndex: Int
    let currentImageIndex: Int
}

final class KemonoImagePointer: ObservableObject {
//    static let shared = ImagePointer()
    private var artistsData = [Artist_show]()
    private var postsFolderName = [String]()
    private var postsId = [Int64]()
    private var currentPostImagesName = [String]()
    
    private var currentArtistIndex = 0
    private var currentPostIndex = 0
    private var currentImageIndex = 0

    @Published var currentImageURL: URL?
    @Published var currentPostDirURL: URL?
    
    private static let postDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
//    init(artistName: String, postsFolderName: [String], postsId: [Int64], currentPostImagesName: [String], currentPostIndex: Int, currentImageIndex: Int) {
//        self.artistName = artistName
//        self.postsFolderName = postsFolderName
//        self.postsId = postsId
//        self.currentPostImagesName = currentPostImagesName
//
//        self.currentPostIndex = currentPostIndex
//        self.currentImageIndex = currentImageIndex
//    }
    
    func loadData(imagePointerData: ImagePointerData) {
        self.artistsData = imagePointerData.artistsData
        self.postsFolderName = imagePointerData.postsFolderName
        self.postsId = imagePointerData.postsId
        self.currentPostImagesName = imagePointerData.currentPostImagesName
        
        self.currentArtistIndex = imagePointerData.currentArtistIndex
        self.currentPostIndex = imagePointerData.currentPostIndex
        self.currentImageIndex = imagePointerData.currentImageIndex
        
        
        currentPostDirURL = getCurrentPostDirURL()
        currentImageURL = getCurrentImageURL()
    }
    
    func isFirstPost() -> Bool {
        return currentPostIndex == 0 && (currentImageIndex == -2 || currentImageIndex == 0)
    }
    
    func isLastPost() -> Bool {
        return currentPostIndex == postsFolderName.count - 1 && (currentImageIndex == -2 || currentImageIndex == currentPostImagesName.count - 1)
    }
    
    func getArtistName() -> String {
        return artistsData[currentArtistIndex].name
    }
    func getArtistService() -> String {
        return artistsData[currentArtistIndex].service
    }
    func getArtistKemonoId() -> String {
        return artistsData[currentArtistIndex].kemonoId
    }
    func getCurrentPostKemonoId() -> String? {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        do {
            let query = KemonoPost.postTable.select(KemonoPost.e_kemonoPostId).filter(KemonoPost.e_postId == postsId[currentPostIndex])
            guard let queryResult = try db.pluck(query) else { return nil }
            return queryResult[KemonoPost.e_kemonoPostId]
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    func getCurrentPostDatetime() -> String {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return "Unknown datetime"
        }
        do {
            let query = KemonoPost.postTable.select(KemonoPost.e_postDate).filter(KemonoPost.e_postId == postsId[currentPostIndex])
            guard let queryResult = try db.pluck(query) else { return "Unknown datetime" }
            let postDatetimeObj = queryResult[KemonoPost.e_postDate]
            return KemonoImagePointer.postDateFormatter.string(from: postDatetimeObj)
        } catch {
            print(error.localizedDescription)
        }
        return "Unknown datetime"
    }
    
    private func getCurrentPostDirURL() -> URL? {
        if postsFolderName.isEmpty { return nil }
        return URL(filePath: Constants.kemonoBaseDir)
            .appendingPathComponent(artistsData[currentArtistIndex].name)
            .appendingPathComponent(postsFolderName[currentPostIndex])
    }
    
    private func getCurrentImageURL() -> URL? {
        if let cpdu = getCurrentPostDirURL() {
            return cpdu.appendingPathComponent(
                currentPostImagesName[currentImageIndex]
            )
        }
        return nil
    }
    
    func nextImage() -> Bool {
        if currentImageIndex >= 0 && currentImageIndex < currentPostImagesName.count - 1 {
            currentImageIndex += 1
            
            currentImageURL = getCurrentImageURL()
            return false
        }
        // last attachment in current post OR no attachment in current post
        if currentImageIndex == currentPostImagesName.count - 1 || currentImageIndex == -2 {
            
            // last attachment in last post
            if currentPostIndex == postsFolderName.count - 1 {
                return false
            }
            
            currentPostIndex += 1
            currentPostImagesName = getImagesName(postId: postsId[currentPostIndex])
            
            NotificationCenter.default.post(
                name: .updateNewViewedPostData,
                object: nil,
                userInfo: ["viewedPostIndex": currentPostIndex]
            )
            
            // no attachments in current post
            if currentPostImagesName.isEmpty {
                currentImageIndex = -2
                
                currentPostDirURL = getCurrentPostDirURL()
                currentImageURL = nil
                return true
            }
            
            // has attachment(s) in current post
            currentImageIndex = 0
            
            currentPostDirURL = getCurrentPostDirURL()
            currentImageURL = getCurrentImageURL()
            return true
        }
        
        currentPostDirURL = nil
        currentImageURL = nil
        return false
    }
    
    func previousImage() -> Bool {
        if currentImageIndex > 0 && currentImageIndex < currentPostImagesName.count {
            currentImageIndex -= 1
            
            currentImageURL = getCurrentImageURL()
            return false
        }
        // first attachment in current post OR no attachment in current post
        if currentImageIndex == 0 || currentImageIndex == -2 {
            
            // first attachment in first post
            if currentPostIndex == 0 {
                return false
            }
            currentPostIndex -= 1
            currentPostImagesName = getImagesName(postId: postsId[currentPostIndex])
            
            NotificationCenter.default.post(
                name: .updateNewViewedPostData,
                object: nil,
                userInfo: ["viewedPostIndex": currentPostIndex]
            )
            
            // no attachments in current post
            if currentPostImagesName.isEmpty {
                currentImageIndex = -2
                
                currentPostDirURL = getCurrentPostDirURL()
                currentImageURL = nil
                return true
            }
            
            // has attachment(s) in current post
            currentImageIndex = currentPostImagesName.count - 1
            
            currentPostDirURL = getCurrentPostDirURL()
            currentImageURL = getCurrentImageURL()
            return true
        }
        
        currentPostDirURL = nil
        currentImageURL = nil
        return false
    }
    
    private func getImagesName(postId: Int64) -> [String] {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return []
        }
        do {
            let query = KemonoImage.imageTable.select(KemonoImage.e_imageName).filter(KemonoImage.e_postIdRef == postId)
            return try db.prepare(query).map {
                $0[KemonoImage.e_imageName]
            }
        } catch {
            print(error.localizedDescription)
        }
        return []
    }
}
