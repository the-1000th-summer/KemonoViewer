//
//  TwitterImagePointer.swift
//  KemonoViewer
//
//  Created on 2025/7/19.
//

import SwiftUI
import SQLite

struct TwitterImagePointerData: Hashable, Codable {
    var id = UUID()
    let artistsName: [String]
    let artistsTwitterId: [String]
    let artistsId: [Int64]
    let currentArtistImagesData: [TwitterImage_show]
    let currentArtistIndex: Int
    let currentImageIndex: Int
    
    let imageQueryConfig: TwitterImageQueryConfig
}

final class TwitterImagePointer: ObservableObject {
    private var artistsName = [String]()
    private var artistsTwitterId = [String]()
    private var artistsId = [Int64]()
    private var currentArtistImagesData = [TwitterImage_show]()
    private var currentArtistIndex = 0
    private var currentImageIndex = 0
    private var imageQueryConfig = TwitterImageQueryConfig()
    
    // 存储点击进入全屏时未浏览的image的信息
    private var notViewedImage_firstLoad: [Int: [Int64]] = [:]
    
    @Published var currentImageURL: URL?
    @Published var currentArtistDirURL: URL?
    
    func loadData(imagePointerData: TwitterImagePointerData) {
        self.artistsName = imagePointerData.artistsName
        self.artistsTwitterId = imagePointerData.artistsTwitterId
        self.artistsId = imagePointerData.artistsId
        self.currentArtistImagesData = imagePointerData.currentArtistImagesData
        self.currentArtistIndex = imagePointerData.currentArtistIndex
        self.currentImageIndex = imagePointerData.currentImageIndex
        self.imageQueryConfig = imagePointerData.imageQueryConfig
        
        currentArtistDirURL = getCurrentArtistDirURL()
        currentImageURL = getCurrentImageURL()
        
        notViewedImage_firstLoad[self.currentArtistIndex] = self.currentArtistImagesData.map { $0.id }
    }
    
    func getArtistName() -> String {
        return artistsName[currentArtistIndex]
    }
    func getArtistTwitterId() -> String {
        return artistsTwitterId[currentArtistIndex]
    }
    
    func getCurrentArtistImagesId() -> Int64 {
        return currentArtistImagesData[currentImageIndex].id
    }
    
    
    func nextImage() -> Bool {
        if currentImageIndex >= 0 && currentImageIndex < currentArtistImagesData.count - 1 {
            currentImageIndex += 1
            currentImageURL = getCurrentImageURL()
            notiPost_newViewedImage()
            return false
        }
        // last attachment in all artist OR no attachment in current post
        if currentImageIndex == currentArtistImagesData.count - 1 || currentImageIndex == -2 {
            // last attachment in last post
            if currentArtistIndex == artistsName.count - 1 {
                return false
            }
            
            currentArtistIndex += 1
            
            if notViewedImage_firstLoad[currentArtistIndex] != nil {
                currentArtistImagesData = TwitterDataReader.readImageData(imagesId: notViewedImage_firstLoad[currentArtistIndex]!, queryConfig: imageQueryConfig) ?? []
            } else {
                currentArtistImagesData = TwitterDataReader.readImageData(artistId: artistsId[currentArtistIndex], queryConfig: imageQueryConfig) ?? []
                notViewedImage_firstLoad[currentArtistIndex] = currentArtistImagesData.map { $0.id }
            }
            
            // no attachments in current artist
            if currentArtistImagesData.isEmpty {
                currentImageIndex = -2
                
                currentArtistDirURL = getCurrentArtistDirURL()
                currentImageURL = nil
                return true
            }
            
            // has attachment(s) in current artist
            currentImageIndex = 0
            currentArtistDirURL = getCurrentArtistDirURL()
            currentImageURL = getCurrentImageURL()
            notiPost_newViewedImage()
            return true
        }
        currentArtistDirURL = nil
        currentImageURL = nil
        return false
    }
    
    private func notiPost_newViewedImage() {
        Task {
            await TwitterDatabaseManager.shared.tagImage(imageId: currentArtistImagesData[currentImageIndex].id, viewed: true)
        }
        
        NotificationCenter.default.post(
            name: .updateNewViewedTwitterImageUI,
            object: nil,
            userInfo: ["currentArtistIndex": currentArtistIndex, "viewedImageIndex": currentImageIndex]
        )
    }
    
    func previousImage() -> Bool {
        if currentImageIndex > 0 && currentImageIndex < currentArtistImagesData.count {
            currentImageIndex -= 1
            currentImageURL = getCurrentImageURL()
            notiPost_newViewedImage()
            return false
        }
        // first attachment in current post OR no attachment in current post
        if currentImageIndex == 0 || currentImageIndex == -2 {
            // first attachment in first post
            if currentArtistIndex == 0 {
                return false
            }
            currentArtistIndex -= 1
            if notViewedImage_firstLoad[currentArtistIndex] != nil {
                currentArtistImagesData = TwitterDataReader.readImageData(imagesId: notViewedImage_firstLoad[currentArtistIndex]!, queryConfig: imageQueryConfig) ?? []
            } else {
                currentArtistImagesData = TwitterDataReader.readImageData(artistId: artistsId[currentArtistIndex], queryConfig: imageQueryConfig) ?? []
                notViewedImage_firstLoad[currentArtistIndex] = currentArtistImagesData.map { $0.id }
            }
            
            // no attachments in current post
            if currentArtistImagesData.isEmpty {
                currentImageIndex = -2
                currentArtistDirURL = getCurrentArtistDirURL()
                currentImageURL = nil
                return true
            }
            
            // has attachment(s) in current post
            currentImageIndex = currentArtistImagesData.count - 1
            
            currentArtistDirURL = getCurrentArtistDirURL()
            currentImageURL = getCurrentImageURL()
            notiPost_newViewedImage()
            
            return true
            
        }
        currentArtistDirURL = nil
        currentImageURL = nil
        return false
    }
    
    
    
    private func getCurrentArtistDirURL() -> URL? {
        if artistsName.isEmpty { return nil }
        return URL(filePath: Constants.twitterBaseDir).appendingPathComponent(artistsTwitterId[currentArtistIndex])
    }
    
    private func getCurrentImageURL() -> URL? {
        return getCurrentArtistDirURL()?.appendingPathComponent(currentArtistImagesData[currentImageIndex].name)
    }
    
    private func getImagesName(artistId: Int64) -> [String] {
        guard let db = TwitterDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return []
        }
        do {
            let query = TwitterImage.imageTable.select(TwitterImage.e_imageName).filter(TwitterImage.e_artistIdRef == artistId)
            return try db.prepare(query).map {
                $0[TwitterImage.e_imageName]
            }
        } catch {
            print(error.localizedDescription)
        }
        return []
    }
    
    func isFirstPost() -> Bool {
        return currentArtistIndex == 0 && (currentImageIndex == -2 || currentImageIndex == 0)
    }
    
    func isLastPost() -> Bool {
        return currentArtistIndex == artistsName.count - 1 && (currentImageIndex == -2 || currentImageIndex == currentArtistImagesData.count - 1)
    }
    
    func loadContent() async -> TweetContent_show? {
        guard let db = TwitterDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        do {
            let query = TwitterImage.imageTable.select(
                TwitterImage.e_tweetId,
                TwitterImage.e_content,
                TwitterImage.e_tweetDate,
                TwitterImage.e_favoriteCount,
                TwitterImage.e_retweetCount,
                TwitterImage.e_replyCount
            ).filter(TwitterImage.e_imageId == getCurrentArtistImagesId())
            guard let pluckResult = try db.pluck(query) else { return nil }
            return TweetContent_show(
                tweetId: pluckResult[TwitterImage.e_tweetId],
                content: pluckResult[TwitterImage.e_content],
                tweet_date: pluckResult[TwitterImage.e_tweetDate],
                favorite_count: Int(pluckResult[TwitterImage.e_favoriteCount]),
                retweet_count: Int(pluckResult[TwitterImage.e_retweetCount]),
                reply_count: Int(pluckResult[TwitterImage.e_replyCount])
            )
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
}
