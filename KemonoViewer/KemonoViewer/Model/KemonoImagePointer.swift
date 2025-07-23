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
    let postsViewed: [Bool]
    
    let currentPostImagesName: [String]
    
    let currentArtistIndex: Int
    let currentPostIndex: Int
    let currentImageIndex: Int
    
    let postQueryConfig: PostQueryConfig
}

final class KemonoImagePointer: ObservableObject {
//    static let shared = ImagePointer()
    private var artistsData = [Artist_show]()
    
    private var postsFolderName = [String]()
    private var postsId = [Int64]()
    private var postsViewed = [Bool]()
    
    private var currentPostImagesName = [String]()
    
    private var currentArtistIndex = 0
    private var currentPostIndex = 0
    private var currentImageIndex = 0
    
    private var postQueryConfig = PostQueryConfig()
    
    // 存储点击进入全屏时未浏览的post的信息
    private var notViewedPost_firstLoad: [Int: [Int64]] = [:]

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
        self.postsViewed = imagePointerData.postsViewed
        
        self.currentPostImagesName = imagePointerData.currentPostImagesName
        
        self.currentArtistIndex = imagePointerData.currentArtistIndex
        self.currentPostIndex = imagePointerData.currentPostIndex
        self.currentImageIndex = imagePointerData.currentImageIndex
        
        self.postQueryConfig = imagePointerData.postQueryConfig
        
        currentPostDirURL = getCurrentPostDirURL()
        currentImageURL = getCurrentImageURL()
        
        notViewedPost_firstLoad[self.currentArtistIndex] = self.postsId
        
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
    
    // 返回post的文件夹是否发生了变化
    func nextImage() -> Bool {
        if currentImageIndex >= 0 && currentImageIndex < currentPostImagesName.count - 1 {
            currentImageIndex += 1
            
            currentImageURL = getCurrentImageURL()
            return false
        }
        //    last attachment in current post
        // OR no attachment in current post
        // OR no post in current artist
        if currentImageIndex == currentPostImagesName.count - 1 || currentImageIndex == -2 {
            
            // last attachment in last post OR no post in current artist
            if currentPostIndex == postsFolderName.count - 1 || currentPostIndex == -2 {
                // last attachment in last post in last artist
                if currentArtistIndex == artistsData.count - 1 {
                    return false
                }
                
                // next artist
                currentArtistIndex += 1
                
                if notViewedPost_firstLoad[currentArtistIndex] != nil {
                    (postsFolderName, postsId, postsViewed) = getPostsData(postsId: notViewedPost_firstLoad[currentArtistIndex]!, queryConfig: postQueryConfig)
                } else {
                    (postsFolderName, postsId, postsViewed) = getPostsData(artistId: artistsData[currentArtistIndex].id)
                    notViewedPost_firstLoad[currentArtistIndex] = postsId
                }
                
                // no not viewed posts in this artist
                if postsFolderName.isEmpty {
                    currentImageIndex = -2
                    currentPostIndex = -2
                    currentPostDirURL = nil
                    currentImageURL = nil
                    return true
                }
                
                currentPostIndex = 0
            } else {
                //     last attachment in current post (current post is not last post)
                // AND current artist has post
                currentPostIndex += 1
            }
            
            currentPostImagesName = getImagesName(postId: postsId[currentPostIndex])
            
            notiPost_newViewedPost()
            
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
        // SHOULD NOT REACH HERE
        currentPostDirURL = nil
        currentImageURL = nil
        return false
    }
    
    private func refreshArtistData(artistIndex: Int, hasNotViewed: Bool) {
        let artistData = artistsData[artistIndex]
        artistsData[artistIndex] = Artist_show(
            name: artistData.name,
            service: artistData.service,
            kemonoId: artistData.kemonoId,
            hasNotViewed: hasNotViewed,
            id: artistData.id
        )
    }
    
    private func notiPost_newViewedPost() {
        postsViewed[currentPostIndex] = true
        
        Task {
            await DatabaseManager.shared.tagPost(postId: postsId[currentPostIndex], viewed: true)
        }
        
        Task {
            let currentArtistShouldUpdateUI = await checkForArtistNotViewed()
            
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .updateNewViewedPostUI,
                    object: nil,
                    userInfo: [
                        "currentArtistIndex": currentArtistIndex,
                        "viewedPostId": postsId[currentPostIndex],
                        "currentArtistShouldUpdateUI": currentArtistShouldUpdateUI
                    ]
                )
            }
        }
    }
    
    private func checkForArtistNotViewed() async -> Bool {
        let artist_hasNotViewed = artistsData[currentArtistIndex].hasNotViewed
        let posts_hasNotViewed = postsViewed.contains { !$0 }
        if artist_hasNotViewed != posts_hasNotViewed {
            refreshArtistData(artistIndex: currentArtistIndex, hasNotViewed: true)
        }
        return artist_hasNotViewed != posts_hasNotViewed
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
            if currentPostIndex == 0 || currentPostIndex == -2 {
                // first attachment in first post in first artist
                if currentArtistIndex == 0 {
                    return false
                }
                
                // previous artist
                currentArtistIndex -= 1
                
                if notViewedPost_firstLoad[currentArtistIndex] != nil {
                    (postsFolderName, postsId, postsViewed) = getPostsData(postsId: notViewedPost_firstLoad[currentArtistIndex]!, queryConfig: postQueryConfig)
                } else {
                    (postsFolderName, postsId, postsViewed) = getPostsData(artistId: artistsData[currentArtistIndex].id)
                    notViewedPost_firstLoad[currentArtistIndex] = postsId
                }
                
                // no not viewed posts in this artist
                if postsFolderName.isEmpty {
                    currentImageIndex = -2
                    currentPostIndex = -2
                    currentPostDirURL = nil
                    currentImageURL = nil
                    return true
                }
                
                currentPostIndex = postsFolderName.count - 1
            } else {
                currentPostIndex -= 1
            }
            
            currentPostImagesName = getImagesName(postId: postsId[currentPostIndex])
            
            notiPost_newViewedPost()
            
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
    
    private func getPostsData(postsId: [Int64], queryConfig: PostQueryConfig) -> ([String], [Int64], [Bool]) {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return ([], [], [])
        }
        
        var query = KemonoPost.postTable.select(KemonoPost.e_postFolderName, KemonoPost.e_postId, KemonoPost.e_viewed).filter(postsId.contains(KemonoPost.e_postId))
        query = DataReader.addQueryConfigFilter(query: query, queryConfig: postQueryConfig)
        
        do {
            let readResult = try db.prepare(query).map {(
                $0[KemonoPost.e_postFolderName],
                $0[KemonoPost.e_postId],
                $0[KemonoPost.e_viewed]
            )}
            return (readResult.map { $0.0 }, readResult.map { $0.1 }, readResult.map { $0.2 })
        } catch {
            print(error.localizedDescription)
        }
        return ([], [], [])
    }
    
    private func getPostsData(artistId: Int64) -> ([String], [Int64], [Bool]) {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return ([], [], [])
        }
        
        var query = KemonoPost.postTable.select(KemonoPost.e_postFolderName, KemonoPost.e_postId, KemonoPost.e_viewed).filter(KemonoPost.e_artistIdRef == artistId)
        query = DataReader.addQueryConfigFilter(query: query, queryConfig: postQueryConfig)
        
        if postQueryConfig.onlyShowNotViewedPost {
            query = query.filter(KemonoPost.e_viewed == false)
        }
        
        do {
            let readResult = try db.prepare(query).map {(
                $0[KemonoPost.e_postFolderName],
                $0[KemonoPost.e_postId],
                $0[KemonoPost.e_viewed]
            )}
            return (readResult.map { $0.0 }, readResult.map { $0.1 }, readResult.map { $0.2 })
        } catch {
            print(error.localizedDescription)
        }
        return ([], [], [])
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
