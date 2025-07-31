//
//  PixivImagePointer.swift
//  KemonoViewer
//
//  Created on 2025/7/26.
//

import Foundation
import SQLite

struct PixivImagePointerData: Hashable, Codable {
    var id = UUID()
    
    let artistsData: [PixivArtist_show]
    let postsData: [PixivPost_show]
    let currentPostImagesName: [String]
    
    let currentArtistIndex: Int
    let currentPostIndex: Int
    let currentImageIndex: Int
    
    let postQueryConfig: PixivPostQueryConfig
}

final class PixivImagePointer: ObservableObject {
    private var artistsData = [PixivArtist_show]()
    
    private var postsFolderName = [String]()
    private var postsId = [Int64]()
    private var postsViewed = [Bool]()
    
    private var currentPostImagesName = [String]()
    
    private var currentArtistIndex = 0
    private var currentPostIndex = 0
    private var currentImageIndex = 0
    
    private var postQueryConfig = PixivPostQueryConfig()
    
    @Published var currentPostDirURL: URL?
    @Published var currentImageURL: URL?
    
    // 存储点击进入全屏时未浏览的post的信息
    private var notViewedPost_firstLoad: [Int: [Int64]] = [:]
    
    func loadData(imagePointerData: PixivImagePointerData) {
        self.artistsData = imagePointerData.artistsData
        
        self.postsFolderName = imagePointerData.postsData.map { $0.folderName }
        self.postsId = imagePointerData.postsData.map { $0.id }
        self.postsViewed = imagePointerData.postsData.map { $0.viewed }
        
        self.currentPostImagesName = imagePointerData.currentPostImagesName
        self.currentArtistIndex = imagePointerData.currentArtistIndex
        self.currentPostIndex = imagePointerData.currentPostIndex
        self.currentImageIndex = imagePointerData.currentImageIndex
        
        self.postQueryConfig = imagePointerData.postQueryConfig
        
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
    func getArtistAvatarURL() -> URL? {
        guard !artistsData[currentArtistIndex].avatarName.isEmpty else { return nil }
        return URL(filePath: Constants.pixivBaseDir).appendingPathComponent(artistsData[currentArtistIndex].folderName)
            .appendingPathComponent(artistsData[currentArtistIndex].avatarName)
    }
    
    func getPostId() -> Int64 {
        return postsId[currentPostIndex]
    }
    
    private func getCurrentPostDirURL() -> URL? {
        if postsFolderName.isEmpty { return nil }
        return URL(filePath: Constants.pixivBaseDir)
            .appendingPathComponent(artistsData[currentArtistIndex].folderName)
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
                    let postsData = PixivDataReader.readPostsData(postsId: notViewedPost_firstLoad[currentArtistIndex]!, queryConfig: postQueryConfig) ?? []
                    postsFolderName = postsData.map { $0.folderName }
                    postsId = postsData.map { $0.id }
                    postsViewed = postsData.map { $0.viewed }
                } else {
                    let postsData = PixivDataReader.readPostData(artistId: artistsData[currentArtistIndex].id, queryConfig: postQueryConfig) ?? []
                    postsFolderName = postsData.map { $0.folderName }
                    postsId = postsData.map { $0.id }
                    postsViewed = postsData.map { $0.viewed }
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
            
            currentPostImagesName = PixivDataReader.readImageData(postId: postsId[currentPostIndex]) ?? []
            
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
                    let postsData = PixivDataReader.readPostsData(postsId: notViewedPost_firstLoad[currentArtistIndex]!, queryConfig: postQueryConfig) ?? []
                    postsFolderName = postsData.map { $0.folderName }
                    postsId = postsData.map { $0.id }
                    postsViewed = postsData.map { $0.viewed }
                } else {
                    let postsData = PixivDataReader.readPostData(artistId: artistsData[currentArtistIndex].id, queryConfig: postQueryConfig) ?? []
                    postsFolderName = postsData.map { $0.folderName }
                    postsId = postsData.map { $0.id }
                    postsViewed = postsData.map { $0.viewed }
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
            
            currentPostImagesName = PixivDataReader.readImageData(postId: postsId[currentPostIndex]) ?? []
            
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
    
    private func notiPost_newViewedPost() {
        postsViewed[currentPostIndex] = true
        
        Task {
            await PixivDatabaseManager.shared.tagPost(postId: postsId[currentPostIndex], viewed: true)
        }
        
        Task {
            let currentArtistShouldUpdateUI = await checkForArtistNotViewed()
            
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .updateNewViewedPixivPostUI,
                    object: nil,
                    userInfo: [
                        "currentArtistId": artistsData[currentArtistIndex].id,
                        "viewedPostId": postsId[currentPostIndex],
                        "currentArtistShouldUpdateUI": currentArtistShouldUpdateUI
                    ]
                )
            }
        }
    }
    
    func loadContentData() async -> PixivContent_show? {
        guard let db = PixivDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        
        let query = PixivPost.postTable.select(
            PixivPost.e_pixivPostId,
            PixivPost.e_postName,
            PixivPost.e_postComment,
            PixivPost.e_postDate,
            PixivPost.e_likeCount,
            PixivPost.e_bookmarkCount,
            PixivPost.e_viewCount,
            PixivPost.e_commentCount,
            PixivPost.e_xRestrict,
            PixivPost.e_isHowto,
            PixivPost.e_isOriginal,
            PixivPost.e_aiType
        ).filter(PixivPost.e_postId == getPostId())
        do {
            guard let pluckResult = try db.pluck(query) else { return nil }
            return PixivContent_show(
                pixivPostId: pluckResult[PixivPost.e_pixivPostId],
                postName: pluckResult[PixivPost.e_postName],
                comment: pluckResult[PixivPost.e_postComment],
                postDate: pluckResult[PixivPost.e_postDate],
                likeCount: Int(pluckResult[PixivPost.e_likeCount]),
                bookmarkCount: Int(pluckResult[PixivPost.e_bookmarkCount]),
                viewCount: Int(pluckResult[PixivPost.e_viewCount]),
                commentCount: Int(pluckResult[PixivPost.e_commentCount]),
                xRestrict: Int(pluckResult[PixivPost.e_xRestrict]),
                isHowto: pluckResult[PixivPost.e_isHowto],
                isOriginal: pluckResult[PixivPost.e_isOriginal],
                aiType: Int(pluckResult[PixivPost.e_aiType])
            )
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    private func checkForArtistNotViewed() async -> Bool {
        let artist_hasNotViewed = artistsData[currentArtistIndex].hasNotViewed
        let posts_hasNotViewed = postsViewed.contains { !$0 }
        if artist_hasNotViewed != posts_hasNotViewed {
            refreshArtistData(artistIndex: currentArtistIndex, hasNotViewed: true)
        }
        return artist_hasNotViewed != posts_hasNotViewed
    }
    
    private func refreshArtistData(artistIndex: Int, hasNotViewed: Bool) {
        let artistData = artistsData[artistIndex]
        artistsData[artistIndex] = PixivArtist_show(
            name: artistData.name,
            folderName: artistData.folderName,
            pixivId: artistData.pixivId,
            avatarName: artistData.avatarName,
            backgroundName: artistData.backgroundName,
            hasNotViewed: hasNotViewed,
            id: artistData.id
        )
    }
}
