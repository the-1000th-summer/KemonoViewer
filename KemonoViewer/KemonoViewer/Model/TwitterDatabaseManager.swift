//
//  TwitterDatabaseManager.swift
//  KemonoViewer
//
//  Created on 2025/7/20.
//

import Foundation
import SQLite

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
    
    static func readImageData(imagesId: [Int64], queryConfig: PostQueryConfig) -> [TwitterImage_show]? {
        guard let db = TwitterDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        do {
            var query = TwitterImage.imageTable.select(TwitterImage.e_imageId, TwitterImage.e_imageName, TwitterImage.e_viewed).filter(imagesId.contains(TwitterImage.e_imageId))
            
            switch queryConfig.sortKey {
            case .date:
                query = query.order(queryConfig.sortOrder == .ascending ? TwitterImage.e_tweetDate.asc : TwitterImage.e_tweetDate.desc)
            case .postTitle:
                query = query.order(queryConfig.sortOrder == .ascending ? TwitterImage.e_content.asc : TwitterImage.e_content.desc)
            }
            
            return try db.prepare(query).map {
                return TwitterImage_show(id: $0[TwitterImage.e_imageId], name: $0[TwitterImage.e_imageName], viewed: $0[TwitterImage.e_viewed])
            }
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    static func readImageData_async(artistId: Int64, queryConfig: PostQueryConfig) async -> [TwitterImage_show]? {
        return readImageData(artistId: artistId, queryConfig: queryConfig)
    }
    
    static func readImageData(artistId: Int64, queryConfig: PostQueryConfig) -> [TwitterImage_show]? {
        
        guard let db = TwitterDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        do {
            var query = TwitterImage.imageTable.select(TwitterImage.e_imageId, TwitterImage.e_imageName, TwitterImage.e_viewed).filter(TwitterImage.e_artistIdRef == artistId)
            
            switch queryConfig.sortKey {
            case .date:
                query = query.order(queryConfig.sortOrder == .ascending ? TwitterImage.e_tweetDate.asc : TwitterImage.e_tweetDate.desc)
            case .postTitle:
                query = query.order(queryConfig.sortOrder == .ascending ? TwitterImage.e_content.asc : TwitterImage.e_content.desc)
            }
            if queryConfig.onlyShowNotViewedPost {
                query = query.filter(TwitterImage.e_viewed == false)
            }
            
            return try db.prepare(query).map {
                return TwitterImage_show(id: $0[TwitterImage.e_imageId], name: $0[TwitterImage.e_imageName], viewed: $0[TwitterImage.e_viewed])
            }
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    
}
