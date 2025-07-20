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
    static let e_kemonoArtistId = Expression<String>("kemono_artist_id")
    static let e_artistName = Expression<String>("name")
    static let e_service = Expression<String>("service")
}

struct KemonoPost {
    static let postTable = Table("kemonoPost")
    static let e_postId = Expression<Int64>("id")
    static let e_kemonoPostId = Expression<String>("kemono_post_id")
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

struct TwitterImage {
    static let imageTable = Table("twitterImage")
    static let e_imageId = Expression<Int64>("id")
    static let e_tweetId = Expression<String>("tweet_id")
    static let e_artistIdRef = Expression<Int64>("artist_id")
    static let e_content = Expression<String>("content")
    static let e_tweetDate = Expression<String>("tweet_date")
    static let e_imageName = Expression<String>("name")
    static let e_favoriteCount = Expression<Int64>("favorite_count")
    static let e_retweetCount = Expression<Int64>("retweet_count")
    static let e_replyCount = Expression<Int64>("reply_count")
    static let e_viewed = Expression<Bool>("viewed")
}

final class TwitterDatabaseManager {
    static let shared = TwitterDatabaseManager()
    private var db: Connection?
    
    private init() {
        initDatabase()
    }
    
    func getConnection() -> Connection? {
        return db
    }
    
    private func initDatabase() {
        let dbFilePath = "/Volumes/imagesShown/twitter.sqlite3"
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
    }
    
    func tagArtist(artistId: Int64, viewed: Bool) {
        do {
            try db?.run(TwitterImage.imageTable.filter(TwitterImage.e_artistIdRef == artistId).update(TwitterImage.e_viewed <- viewed))
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func tagImage(imageId: Int64, viewed: Bool) async {
        do {
            try db?.run(TwitterImage.imageTable.filter(TwitterImage.e_imageId == imageId).update(TwitterImage.e_viewed <- viewed))
        } catch {
            print(error.localizedDescription)
            return
        }
    }
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
                t.column(Artist.e_artistId, primaryKey: true)
                t.column(Artist.e_kemonoArtistId)
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
    
    func tagPost(postId: Int64, viewed: Bool) async {
        do {
            try db?.run(KemonoPost.postTable.filter(KemonoPost.e_postId == postId).update(KemonoPost.e_viewed <- viewed))
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

struct Artist_write {
    let name: String
    let kemonoID: String
    let service: String
}

final class DataWriter {
    private static let sharedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    static func getArtistIdAndService(artistDirPath: String) -> Artist_write? {
        guard let postsName = getSubdirectoryNames(atPath: artistDirPath), !postsName.isEmpty else { return nil }
        let firstPostJsonFileURL = URL(filePath: artistDirPath).appendingPathComponent(postsName[0]).appendingPathComponent("post.json")
        guard let jsonFileData = try? Data(contentsOf: firstPostJsonFileURL) else {
            print("打开Json文件失败")
            return nil
        }
        guard let jsonObj = try? JSON(data: jsonFileData) else {
            print("转换为Json对象失败")
            return nil
        }
        
        let service = jsonObj["service"].stringValue
        let userId = jsonObj["user"].stringValue
        return Artist_write(name: URL(filePath: artistDirPath).lastPathComponent, kemonoID: userId, service: service)
    }
    
    static func writeArtistDataToDatabase(artistData: Artist_write) -> Int64? {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        do {
            let artistId_upload = try db.run(Artist.artistTable.insert(
                Artist.e_artistName <- artistData.name,
                Artist.e_service <- artistData.service
            ))
            return artistId_upload
        } catch {
            print("save artist data error:", error.localizedDescription)
            return nil
        }
    }
    
    static func writeKemonoDataToDatabase(isProcessing: SwiftUI.Binding<Bool>, progress: SwiftUI.Binding<Double>) async {
        
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

                try! db.transaction {
                    
                    guard let artistData = getArtistIdAndService(artistDirPath: getArtistDirPath(artistName: artistName)) else { return }
                    
                    guard let artistId = writeArtistDataToDatabase(artistData: artistData) else {
                        print("Write artist data to database failed.")
                        return
                    }
                    
                    for postName in postsName.prefix(10) {
                        let currentPostDirPath = URL(filePath:artistDirPath).appendingPathComponent(postName).path(percentEncoded: false)
                        
                        let currentPostJsonFileURL = URL(filePath: currentPostDirPath).appendingPathComponent("post.json")
                        guard let currentJsonFileData = try? Data(contentsOf: currentPostJsonFileURL) else {
                            print("\(currentPostJsonFileURL.path(percentEncoded: false)): 打开Json文件失败")
                            continue
                        }
                        guard let jsonObj = try? JSON(data: currentJsonFileData) else {
                            print("转换为Json对象失败")
                            return
                        }
                        writePostDataToDatabase(artistID: artistId, postData: jsonObj)
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
    
    static func writePostBatchesDataToDatabase(artistId: Int64, postBatchesData: [JSON]) {
        for oneBatchData in postBatchesData {
            for onePostData in oneBatchData {
                writePostDataToDatabase(artistID: artistId, postData: onePostData.1)
            }
            
        }
    }
    
    static func writePostDataToDatabase(artistID: Int64, postData jsonObj: JSON) {
        
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return
        }
        
        do {
            // post data
            let postDateStr = String(jsonObj["published"].stringValue.split(separator: ".")[0]) + "Z"
            let postDate = sharedFormatter.date(from: postDateStr)!
            let postId = try db.run(KemonoPost.postTable.insert(
                KemonoPost.e_artistIdRef <- artistID,
                KemonoPost.e_postName <- jsonObj["title"].stringValue,
                KemonoPost.e_postDate <- postDate,
                KemonoPost.e_coverImgFileName <- jsonObj["id"].stringValue + "_" + jsonObj["file"]["name"].stringValue,
                KemonoPost.e_postFolderName <- "",
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
            print("Save post data error:", error.localizedDescription)
        }
    }
    
    static func getDataFromKemonoApi(isProcessing: SwiftUI.Binding<Bool>, progress: SwiftUI.Binding<Double>) async {
        
        await MainActor.run {
            isProcessing.wrappedValue = true
            progress.wrappedValue = 0.0
        }
        
        print("dfdf")
        
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return
        }
        
        let inputFolderPath = "/Volumes/ACG/kemono"
        let batchSize = 5
        
        guard let artistsName = getSubdirectoryNames(atPath: inputFolderPath) else { return }
        
        
        for batchStart in stride(from: 0, to: artistsName.count, by: batchSize) {
            let batchIds = Array(batchStart..<min(batchStart+batchSize, artistsName.count))
            
            let batchData = await withTaskGroup(of: (Int, [JSON]?).self) { group -> [(Int, [JSON])] in
                for id in batchIds {
                    group.addTask {
                        let artistDirPath = getArtistDirPath(artistName: artistsName[id])
                        
                        var jsons: [JSON] = []
                        var page = 1
                        while true {
                            do {
                                guard let url = getArtistPostsApi(artistDirPath: artistDirPath, page: page) else { return (-1, nil) }
                                let fetcheddata = try await fetchData(from: url)
                                guard let jsonObj = try? JSON(data: fetcheddata) else {
                                    print("转换为Json对象失败")
                                    return (id, nil)
                                }
                                if jsonObj.isEmpty {
                                    break
                                }
                                jsons.append(jsonObj)
                                page += 1
                            } catch {
                                print("获取ID \(id)失败: \(error)")
                                return (id, nil)
                            }
                        }
                        return (id, jsons)
                    }
                }
                var results = [(Int, [JSON])]()
                for await (id, jsonData) in group {
                    if let jsonData {
                        results.append((id, jsonData))
                    }
                }
                return results
            }
            
            let sortedBatch = batchData.sorted(by: { $0.0 < $1.0 })
            
            try! db.transaction {
                for oneDataInBatch in sortedBatch {
                    guard let artistData = getArtistIdAndService(artistDirPath: getArtistDirPath(artistName: artistsName[oneDataInBatch.0])) else { continue }
                    
                    guard let artistId = writeArtistDataToDatabase(artistData: artistData) else { continue }
                    writePostBatchesDataToDatabase(artistId: artistId, postBatchesData: oneDataInBatch.1)
                    
                }
            }
            await MainActor.run {
                progress.wrappedValue = Double(batchStart) / Double(artistsName.count)
            }
        }
            
        await MainActor.run {
            isProcessing.wrappedValue = false
        }
    }
    
    static func getArtistDirPath(artistName: String) -> String {
        let inputFolderPath = "/Volumes/ACG/kemono"
        return URL(filePath: inputFolderPath).appendingPathComponent(artistName).path(percentEncoded: false)
    }
    
    static func getArtistPostsApi(artistDirPath: String, page: Int) -> URL? {
        guard let artistData = getArtistIdAndService(artistDirPath: artistDirPath) else { return nil}
        
        var urlStr = "https://kemono.su/api/v1/\(artistData.service)/user/\(artistData.kemonoID)"
        if page > 1 {
            urlStr += "?o=\((page-1)*50)"
        }
        return URL(string: urlStr)
    }
    
    static func fetchData(from apiUrl: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: apiUrl)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

final class DataReader {
    static func readArtistData(queryConfig: ArtistQueryConfig) async -> [Artist_show]? {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        
        var sqlStr = """
        SELECT
          a."name",
          a."service",
          a."kemono_artist_id",
          a."id",
          EXISTS(
            SELECT 1
            FROM "kemonoPost"
            WHERE "artist_id" = a."id" AND "viewed" = 0
          ) AS has_unviewed
        FROM "artist" AS a
        """
        if queryConfig.onlyShowNotFullyViewedArtist {
            sqlStr += """
                
                WHERE EXISTS (
                  SELECT 1
                  FROM "kemonoPost"
                  WHERE "artist_id" = a."id" AND "viewed" = 0
                )
                """
        }
        
        do {
            return try db.prepare(sqlStr).map { row in
                Artist_show(
                    name: row[0] as! String,
                    service: row[1] as! String,
                    kemonoId: row[2] as! String,
                    hasNotViewed: (row[4] as! Int64 == 1),
                    id: row[3] as! Int64
                )
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    static func readPostData(artistId: Int64, queryConfig: PostQueryConfig) -> [Post_show]? {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        var postsData = [Post_show]()
        
        
        var query = KemonoPost.postTable.select(
            KemonoPost.e_postName,
            KemonoPost.e_postFolderName,
            KemonoPost.e_coverImgFileName,
            KemonoPost.e_postId,
            KemonoPost.e_attachmentNumber,
            KemonoPost.e_postDate,
            KemonoPost.e_viewed
        ).filter(KemonoPost.e_artistIdRef == artistId)
        switch queryConfig.sortKey {
        case .date:
            query = query.order(queryConfig.sortOrder == .ascending ? KemonoPost.e_postDate.asc : KemonoPost.e_postDate.desc)
        case .postTitle:
            query = query.order(queryConfig.sortOrder == .ascending ? KemonoPost.e_postName.asc : KemonoPost.e_postName.desc)
        }
        if queryConfig.onlyShowNotViewedPost {
            query = query.filter(KemonoPost.e_viewed == false)
        }
        
        do {
            
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
    
    static func readImageData(postId: Int64) async -> ([String]?, String?) {
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

final class TwitterDataReader {
    static func readArtistData(queryConfig: ArtistQueryConfig) async -> [TwitterArtist_show]? {
        guard let db = TwitterDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        
        var sqlStr = """
        SELECT
          a."name",
          a."twitter_artist_id",
          a."id",
          EXISTS(
            SELECT 1
            FROM "twitterImage"
            WHERE "artist_id" = a."id" AND "viewed" = 0
          ) AS has_unviewed
        FROM "twitterArtist" AS a
        """
        if queryConfig.onlyShowNotFullyViewedArtist {
            sqlStr += """
                
                WHERE EXISTS (
                  SELECT 1
                  FROM "kemonoPost"
                  WHERE "artist_id" = a."id" AND "viewed" = 0
                )
                """
        }
        
        do {
            return try db.prepare(sqlStr).map { row in
                TwitterArtist_show(
                    name: row[0] as! String,
                    twitterId: row[1] as! String,
                    hasNotViewed: (row[3] as! Int64 == 1),
                    id: row[2] as! Int64
                )
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    static func readImageData(artistId: Int64) async -> [TwitterImage_show]? {
        
        guard let db = TwitterDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        do {
            let query = TwitterImage.imageTable.select(TwitterImage.e_imageId, TwitterImage.e_imageName, TwitterImage.e_viewed).filter(TwitterImage.e_artistIdRef == artistId)
            
            return try db.prepare(query).map {
                return TwitterImage_show(id: $0[TwitterImage.e_imageId], name: $0[TwitterImage.e_imageName], viewed: $0[TwitterImage.e_viewed])
            }
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

extension Notification.Name {
    static let updateNewViewedPostData = Notification.Name("UpdateNewViewedPostDataNotification")
    static let updateAllPostViewedStatus = Notification.Name("updateAllPostViewedStatusNotification")
    
    static let updateNewViewedTwitterImageData = Notification.Name("updateNewViewedTwitterImageDataNotification")
    static let updateAllTwitterImageViewedStatus = Notification.Name("updateAllTwitterImageViewedStatusNotification")
}

