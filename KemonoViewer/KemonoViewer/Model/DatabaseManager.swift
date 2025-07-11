//
//  DatabaseManager.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import Foundation
import SwiftUI
import SQLite
import SwiftyJSON

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
    private let dateFormatter = DateFormatter()
    
    private init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        initDatabase()
    }
    
    func getConnection() -> Connection? {
        return db
    }
    
    private func initDatabase() {
        let dbFilePath = "/Volumes/imagesShown/images_python.sqlite3"
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
                t.column(Artist.e_artistId, primaryKey: true)
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
                t.column(KemonoPost.e_postId, primaryKey: true)
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
                t.column(KemonoImage.e_imageId, primaryKey: true)
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
    
    func tagArtist(artistId: Int64, viewed: Bool) {
        do {
            try db?.run(KemonoPost.postTable.filter(KemonoPost.e_artistIdRef == artistId).update(KemonoPost.e_viewed <- viewed))
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func tagPost(postId: Int64, viewed: Bool) {
        do {
            try db?.run(KemonoPost.postTable.filter(KemonoPost.e_postId == postId).update(KemonoPost.e_viewed <- viewed))
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func writeKemonoDataToDatabase(isProcessing: SwiftUI.Binding<Bool>, progress: SwiftUI.Binding<Double>) async {
        
        await MainActor.run {
            isProcessing.wrappedValue = true
            progress.wrappedValue = 0.0
        }
        
        let inputFolderPath = "/Volumes/ACG/kemono"
        
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return
        }
        
        guard let artistsName = getSubdirectoryNames(atPath: inputFolderPath) else { return }
        for (i, artistName) in artistsName.enumerated() {
            let artistDirPath = URL(filePath: inputFolderPath).appendingPathComponent(artistName).path(percentEncoded: false)
            if let postsName = getSubdirectoryNames(atPath: artistDirPath) {
                var artistId: Int64? = nil
                var a = 0
                try! db.transaction {
                    for postName in postsName.prefix(10) {
                        let currentPostDirPath = URL(filePath:artistDirPath).appendingPathComponent(postName).path(percentEncoded: false)
                        
                        artistId = handleOnePost(postDirPath: currentPostDirPath, artistId: artistId)
                        a += 1
                        print(a)
                    }
                }
            }
            
            await MainActor.run {
                progress.wrappedValue = Double(i) / Double(artistsName.count)
            }
                    
        }
        
        await MainActor.run {
            isProcessing.wrappedValue = false
        }
    }
    
    func handleOnePost(postDirPath: String, artistId: Int64?) -> Int64? {
        let postJsonFileURL = URL(filePath: postDirPath).appendingPathComponent("post.json")
        guard let jsonFileData = try? Data(contentsOf: postJsonFileURL) else {
            print("打开Json文件失败")
            return nil
        }
        guard let jsonObj = try? JSON(data: jsonFileData) else {
            print("转换为Json对象失败")
            return nil
        }
        guard let db else {
            print("数据库初始化失败")
            return nil
        }
        
        var artistId_upload: Int64? = nil
        do {
            // artist data
            let artistName = URL(filePath: postDirPath).deletingLastPathComponent().lastPathComponent
            if let artistId {
                artistId_upload = artistId
            } else {
                artistId_upload = try db.run(Artist.artistTable.insert(
                    Artist.e_artistName <- artistName,
                    Artist.e_service <- jsonObj["service"].stringValue
                ))
            }

            // post data
            let postDateStr = jsonObj["published"].stringValue + "Z"
            let postDate = dateFormatter.date(from: postDateStr)!
            let postId = try db.run(KemonoPost.postTable.insert(
                KemonoPost.e_artistIdRef <- artistId_upload!,
                KemonoPost.e_postName <- jsonObj["title"].stringValue,
                KemonoPost.e_postDate <- postDate,
                KemonoPost.e_coverImgFileName <- jsonObj["id"].stringValue + "_" + jsonObj["file"]["name"].stringValue,
                KemonoPost.e_postFolderName <- URL(filePath: postDirPath).lastPathComponent,
                KemonoPost.e_attachmentNumber <- Int64(jsonObj["attachments"].arrayValue.count)
            ))
            
            // attachment data
            for (i, attachment) in jsonObj["attachments"].arrayValue.enumerated() {
                let fileExt = URL(filePath: attachment["name"].stringValue).pathExtension
                try db.run(KemonoImage.imageTable.insert(
                    KemonoImage.e_postIdRef <- postId,
                    KemonoImage.e_imageName <- String(i+1) + "." + fileExt
                ))
            }
        } catch {
            print("save:", error.localizedDescription)
        }
        
        return artistId_upload
        
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
    @Published var currentPostDirURL: URL?
    
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
        
        
        currentPostDirURL = getCurrentPostDirURL()
        currentImageURL = getCurrentImageURL()
//        return nil
    }
    
    func isFirstPost() -> Bool {
        return currentPostIndex == 0 && (currentImageIndex == -2 || currentImageIndex == 0)
    }
    
    func isLastPost() -> Bool {
        return currentPostIndex == postsFolderName.count - 1 && (currentImageIndex == -2 || currentImageIndex == currentPostImagesName.count - 1)
    }
    
    private func getCurrentPostDirURL() -> URL? {
        if postsFolderName.isEmpty { return nil }
        return URL(filePath: inputFolderPath)
            .appendingPathComponent(artistName)
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

extension Notification.Name {
    static let updateNewViewedPostData = Notification.Name("UpdateNewViewedPostDataNotification")
    static let updateAllPostViewedStatus = Notification.Name("updateAllPostViewedStatusNotification")
}

