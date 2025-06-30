//
//  DatabaseManager.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import Foundation
import SQLite

struct Artist {
    static let artistTable = Table("artist")
    static let e_artistId = Expression<Int64>("id")
    static let e_artistName = Expression<String>("name")
    static let e_service = Expression<String>("service")
}

struct KemonoPost {
    static let postTable = Table("kemonoPost")
    static let e_postId = Expression<Int64>("id")
    static let e_artistIdRef = Expression<Int64>("artist_id")
    static let e_postName = Expression<String>("name")
    static let e_postDate = Expression<Date>("post_date")
    static let e_coverImgFileName = Expression<String>("cover_name")
    static let e_postFolderName = Expression<String>("folder_name")
    static let e_attachmentNumber = Expression<Int64>("att_number")
    static let e_viewed = Expression<Bool>("viewed")
}

struct KemonoImage {
    static let imageTable = Table("kemonoImage")
    static let e_imageId = Expression<Int64>("id")
    static let e_postIdRef = Expression<Int64>("post_id")
    static let e_imageName = Expression<String>("name")
}

final class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?
    
    private init() {
        initDatabase()
    }
    
    func getConnection() -> Connection? {
        return db
    }
    
    private func initDatabase() {
        let dbFilePath = "/Volumes/imagesShown/images.sqlite3"
        let fm = FileManager.default
        
        if fm.fileExists(atPath: dbFilePath) {
            do {
                db = try Connection(dbFilePath)
            } catch {
                db = nil
                print(error.localizedDescription)
            }
        } else {
            do {
                db = try Connection(dbFilePath)
                createTable(db: db!)
            } catch {
                db = nil
                print(error.localizedDescription)
            }
        }
    }
    
    func createTable(db: Connection) {
        // artist
        
        do {
            try db.run(Artist.artistTable.create { t in
                t.column(Artist.e_artistId, primaryKey: .autoincrement)
                t.column(Artist.e_artistName)
                t.column(Artist.e_service)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
        
        // post
        do {
            try db.run(KemonoPost.postTable.create { t in
                t.column(KemonoPost.e_postId, primaryKey: .autoincrement)
                t.column(KemonoPost.e_artistIdRef)
                t.column(KemonoPost.e_postName)
                t.column(KemonoPost.e_postDate)
                t.column(KemonoPost.e_coverImgFileName)
                t.column(KemonoPost.e_postFolderName)
                t.column(KemonoPost.e_attachmentNumber)
                t.column(KemonoPost.e_viewed, defaultValue: false)
                
                t.foreignKey(KemonoPost.e_artistIdRef, references: Artist.artistTable, Artist.e_artistId, delete: .cascade)
            })
            
        } catch {
            print(error.localizedDescription)
            return
        }
        
        // image
        do {
            try db.run(KemonoImage.imageTable.create { t in
                t.column(KemonoImage.e_imageId, primaryKey: .autoincrement)
                t.column(KemonoImage.e_postIdRef)
                t.column(KemonoImage.e_imageName)
                
                t.foreignKey(KemonoImage.e_postIdRef, references: KemonoPost.postTable, KemonoPost.e_postId, delete: .cascade)
            })
            
            try db.execute("PRAGMA foreign_keys = ON")
        } catch {
            print(error.localizedDescription)
            return
        }
        
    }
}

struct Post_show {
    let name: String
    let folderName: String
    let id: Int64
    let viewed: Bool
}


final class DataReader {
    static func readArtistData() -> [Artist_show]? {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        var artistsData = [Artist_show]()
        
        do {
            for row in try db.prepare(Artist.artistTable.select(Artist.e_artistName, Artist.e_artistId)) {
                artistsData.append(Artist_show(
                    name: row[Artist.e_artistName],
                    id: row[Artist.e_artistId]
                ))
            }
//            artistsName = try db.prepare(Artist.artistTable.select(Artist.e_artistName)).map { row in
//                return row[Artist.e_artistName] // 返回 String? 类型
//            }
        } catch {
            print(error.localizedDescription)
        }
        
        return artistsData
    }
    
    static func readPostData(artistId: Int64) -> [Post_show]? {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        var postsData = [Post_show]()
        
        do {
            var query = KemonoPost.postTable.select(
                KemonoPost.e_postName,
                KemonoPost.e_postFolderName,
                KemonoPost.e_postId,
                KemonoPost.e_viewed
            ).filter(KemonoPost.e_artistIdRef == artistId)
//            if notViewedFilterSwitch.state == .on {
//                query = query.filter(KemonoPost.e_viewed == false)
//            }
            for row in try db.prepare(query) {
                let currentPost = Post_show(
                    name: row[KemonoPost.e_postName],
                    folderName: row[KemonoPost.e_postFolderName],
                    id: row[KemonoPost.e_postId],
                    viewed: row[KemonoPost.e_viewed]
                )
                postsData.append(currentPost)
            }
        } catch {
            print(error.localizedDescription)
        }
        return postsData
    }
    
    static func readImageData(postId: Int64) -> ([String]?, String?) {
        var imagesName = [String]()
        
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return (nil, nil)
        }
        do {
            let imageNameQuery = KemonoImage.imageTable.select(KemonoImage.e_imageName).filter(KemonoImage.e_postIdRef == postId)
            for row in try db.prepare(imageNameQuery) {
                imagesName.append(row[KemonoImage.e_imageName])
//                postsId.append(row[KemonoPost.e_postId])
            }
            
            
            let postFolderNameQuery = KemonoPost.postTable.select(KemonoPost.e_postFolderName, KemonoPost.e_artistIdRef).filter(KemonoPost.e_postId == postId)
            guard let postFolderQueryResult = try db.pluck(postFolderNameQuery) else {
                return (imagesName, nil)
            }
            
            let postFolderName = postFolderQueryResult[KemonoPost.e_postFolderName]
            let artistId = postFolderQueryResult[KemonoPost.e_artistIdRef]
            
            let artistNameQuery = Artist.artistTable.select(Artist.e_artistName).filter(Artist.e_artistId == artistId)
            if let artistQueryResult = try db.pluck(artistNameQuery) {
                let artistName = artistQueryResult[Artist.e_artistName]
                let postDirPath = URL(filePath: "/Volumes/ACG/kemono").appendingPathComponent(artistName).appendingPathComponent(postFolderName).path(percentEncoded: false)
                return (imagesName, postDirPath)
            }
            
        } catch {
            print(error.localizedDescription)
            return (nil, nil)
        }
        return (nil, nil)
    }
}

final class ImagePointer {
//    static let shared = ImagePointer()
    private var artistName = ""
    private var postsFolderName = [String]()
    private var postsId = [Int64]()
    private var currentPostImagesName = [String]()
    
    private var currentArtistIndex = 0
    private var currentPostIndex = 0
    private var currentImageIndex = 0
    
    private let inputFolderPath = "/Volumes/ACG/kemono"
    
    init(artistName: String, postsFolderName: [String], postsId: [Int64], currentPostImagesName: [String], currentPostIndex: Int, currentImageIndex: Int) {
        self.artistName = artistName
        self.postsFolderName = postsFolderName
        self.postsId = postsId
        self.currentPostImagesName = currentPostImagesName
        
        self.currentPostIndex = currentPostIndex
        self.currentImageIndex = currentImageIndex
    }
    
    func getCurrentPostDirURL() -> URL {
        return URL(filePath: inputFolderPath)
            .appendingPathComponent(artistName)
            .appendingPathComponent(postsFolderName[currentPostIndex])
    }
    
    func getCurrentImageURL() -> URL {
        return getCurrentPostDirURL().appendingPathComponent(
            currentPostImagesName[currentImageIndex]
        )
    }
    
    
    
    func getNextImageURL() -> (URL?, URL?) {
        if currentImageIndex >= 0 && currentImageIndex < currentPostImagesName.count - 1 {
            currentImageIndex += 1
            return (getCurrentImageURL(), nil)
        }
        // last image in current post OR no attachment in current post
        if currentImageIndex == currentPostImagesName.count - 1 || currentImageIndex == -2 {
            if currentPostIndex == postsFolderName.count - 1 { return (nil, nil) }
            currentPostIndex += 1
            currentPostImagesName = getImagesName(postId: postsId[currentPostIndex])
            if currentPostImagesName.isEmpty {
                currentImageIndex = -2
                return (nil, getCurrentPostDirURL())
            }
            currentImageIndex = 0
            
            NotificationCenter.default.post(
                name: .updatePostTableViewData,
                object: nil,
                userInfo: ["viewedPostIndex": currentPostIndex]
            )
            
            return (getCurrentImageURL(), getCurrentPostDirURL())
        }
        return (nil, nil)
    }
    
    func getPreviousImageURL() -> (URL?, URL?) {
        if currentImageIndex > 0 && currentImageIndex < currentPostImagesName.count {
            currentImageIndex -= 1
            return (getCurrentImageURL(), nil)
        }
        // first image in current post OR no attachment in current post
        if currentImageIndex == 0 || currentImageIndex == -2 {
            if currentPostIndex == 0 { return (nil, nil) }
            currentPostIndex -= 1
            currentPostImagesName = getImagesName(postId: postsId[currentPostIndex])
            if currentPostImagesName.isEmpty {
                currentImageIndex = -2
                return (nil, getCurrentPostDirURL())
            }
            currentImageIndex = currentPostImagesName.count - 1
            
            NotificationCenter.default.post(
                name: .updatePostTableViewData,
                object: nil,
                userInfo: ["viewedPostIndex": currentPostIndex]
            )
            return (getCurrentImageURL(), getCurrentPostDirURL())
        }
        return (nil, nil)
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

extension Notification.Name {
    static let updatePostTableViewData = Notification.Name("UpdatePostTableViewDataNotification")
}

