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
    
    func tagViewedPost(viewedPostId: Int64) {
        do {
            try db?.run(KemonoPost.postTable.filter(KemonoPost.e_postId == viewedPostId).update(KemonoPost.e_viewed <- true))
        } catch {
            print(error.localizedDescription)
            return
        }
    }
}

struct Post_show {
    let name: String
    let folderName: String
    let coverName: String
    let id: Int64
    let attNumber: Int
    let postDate: Date
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
    
    static func readPostData(artistId: Int64, notViewedToggleisOn: Bool) -> [Post_show]? {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        var postsData = [Post_show]()
        
        do {
            var query = KemonoPost.postTable.select(
                KemonoPost.e_postName,
                KemonoPost.e_postFolderName,
                KemonoPost.e_coverImgFileName,
                KemonoPost.e_postId,
                KemonoPost.e_attachmentNumber,
                KemonoPost.e_postDate,
                KemonoPost.e_viewed
            ).filter(KemonoPost.e_artistIdRef == artistId)
            if notViewedToggleisOn {
                query = query.filter(KemonoPost.e_viewed == false)
            }
            for row in try db.prepare(query) {
                let currentPost = Post_show(
                    name: row[KemonoPost.e_postName],
                    folderName: row[KemonoPost.e_postFolderName],
                    coverName: row[KemonoPost.e_coverImgFileName],
                    id: row[KemonoPost.e_postId],
                    attNumber: Int(row[KemonoPost.e_attachmentNumber]),
                    postDate: row[KemonoPost.e_postDate],
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

struct ImagePointerData: Hashable, Codable {
    var id = UUID()
    let artistName: String
    let postsFolderName: [String]
    let postsId: [Int64]
    let currentPostImagesName: [String]
    let currentPostIndex: Int
    let currentImageIndex: Int
}

final class ImagePointer: ObservableObject {
//    static let shared = ImagePointer()
    private var artistName = ""
    private var postsFolderName = [String]()
    private var postsId = [Int64]()
    private var currentPostImagesName = [String]()
    
    private var currentArtistIndex = 0
    private var currentPostIndex = 0
    private var currentImageIndex = 0

    @Published var currentImageURL: URL?
//    @Published var currentPostDirURL: URL?
    
    private let inputFolderPath = "/Volumes/ACG/kemono"
    
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
        print("loadData")
        self.artistName = imagePointerData.artistName
        self.postsFolderName = imagePointerData.postsFolderName
        self.postsId = imagePointerData.postsId
        self.currentPostImagesName = imagePointerData.currentPostImagesName
        self.currentPostIndex = imagePointerData.currentPostIndex
        self.currentImageIndex = imagePointerData.currentImageIndex
        
        currentImageURL = getCurrentImageURL()
//        return nil
    }
    
    func getCurrentPostDirURL() -> URL {
        return URL(filePath: inputFolderPath)
            .appendingPathComponent(artistName)
            .appendingPathComponent(postsFolderName[currentPostIndex])
    }
    
    private func getCurrentImageURL() -> URL {
        return getCurrentPostDirURL().appendingPathComponent(
            currentPostImagesName[currentImageIndex]
        )
    }
    
    func nextImage() -> URL? {
        if currentImageIndex >= 0 && currentImageIndex < currentPostImagesName.count - 1 {
            currentImageIndex += 1
            
            currentImageURL = getCurrentImageURL()
            return nil
        }
        // last image in current post OR no attachment in current post
        if currentImageIndex == currentPostImagesName.count - 1 || currentImageIndex == -2 {
            if currentPostIndex == postsFolderName.count - 1 {
                return nil
            }
            currentPostIndex += 1
            currentPostImagesName = getImagesName(postId: postsId[currentPostIndex])
            
            if currentPostImagesName.isEmpty {
                currentImageIndex = -2
//                return (nil, getCurrentPostDirURL())
                currentImageURL = nil
                return getCurrentPostDirURL()
            }
            currentImageIndex = 0
            
            NotificationCenter.default.post(
                name: .updatePostTableViewData,
                object: nil,
                userInfo: ["viewedPostIndex": currentPostIndex]
            )
            
            currentImageURL = getCurrentImageURL()
            return getCurrentPostDirURL()
        }
        currentImageURL = nil
        return nil
    }
    
    func previousImage() -> URL? {
        if currentImageIndex > 0 && currentImageIndex < currentPostImagesName.count {
            currentImageIndex -= 1
            
            currentImageURL = getCurrentImageURL()
            return nil
        }
        // first image in current post OR no attachment in current post
        if currentImageIndex == 0 || currentImageIndex == -2 {
            if currentPostIndex == 0 {
                return nil
            }
            currentPostIndex -= 1
            currentPostImagesName = getImagesName(postId: postsId[currentPostIndex])
            if currentPostImagesName.isEmpty {
                currentImageIndex = -2
                currentImageURL = nil
                return getCurrentPostDirURL()
            }
            currentImageIndex = currentPostImagesName.count - 1
            
            NotificationCenter.default.post(
                name: .updatePostTableViewData,
                object: nil,
                userInfo: ["viewedPostIndex": currentPostIndex]
            )
            currentImageURL = getCurrentImageURL()
            return getCurrentPostDirURL()
        }
        currentImageURL = nil
        return nil
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

