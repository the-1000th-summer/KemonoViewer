//
//  PixivDatabaseManager.swift
//  KemonoViewer
//
//  Created on 2025/7/23.
//

import Foundation
import SQLite

struct PixivPost {
    static let postTable = Table("pixivPost")
    static let e_postId = Expression<Int64>("id")
    static let e_pixivPostId = Expression<String>("pixiv_post_id")
    static let e_artistIdRef = Expression<Int64>("artist_id")
    static let e_postName = Expression<String>("name")
    static let e_postDate = Expression<Date>("post_date")
    static let e_postFolderName = Expression<String>("post_folder_name")
    static let e_imageNumber = Expression<Int64>("image_number")
    static let e_viewed = Expression<Bool>("viewed")
}

class PixivDatabaseManager {
    static let shared = PixivDatabaseManager()
    private var db: Connection?
    
    private init() {
        initDatabase()
    }
    
    func getConnection() -> Connection? {
        return db
    }
    
    private func initDatabase() {
        let fm = FileManager.default
        
        if fm.fileExists(atPath: Constants.pixivDatabaseFilePath) {
            do {
                db = try Connection(Constants.pixivDatabaseFilePath)
            } catch {
                db = nil
                print(error.localizedDescription)
            }
        } else {
            do {
                db = try Connection(Constants.pixivDatabaseFilePath)
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
            try db?.run(PixivPost.postTable.filter(PixivPost.e_artistIdRef == artistId).update(PixivPost.e_viewed <- viewed))
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
}

final class PixivDataReader {
    static func readArtistData(queryConfig: ArtistQueryConfig) async -> [PixivArtist_show]? {
        guard let db = PixivDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        
        var sqlStr = """
        SELECT
          a."name",
          a."artist_folder_name",
          a."pixiv_artist_id",
          a."id",
          EXISTS(
            SELECT 1
            FROM "pixivPost"
            WHERE "artist_id" = a."id" AND "viewed" = 0
          ) AS has_unviewed
        FROM "pixivArtist" AS a
        """
        if queryConfig.onlyShowNotFullyViewedArtist {
            sqlStr += """
                
                WHERE EXISTS (
                  SELECT 1
                  FROM "pixivPost"
                  WHERE "artist_id" = a."id" AND "viewed" = 0
                )
                """
        }
        
        do {
            return try db.prepare(sqlStr).map { row in
                PixivArtist_show(
                    name: row[0] as! String,
                    folderName: row[1] as! String,
                    pixivId: row[2] as! String,
                    hasNotViewed: (row[4] as! Int64 == 1),
                    id: row[3] as! Int64
                )
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    static func readPostData(artistId: Int64, queryConfig: PixivPostQueryConfig) -> [PixivPost_show]? {
        guard let db = PixivDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        var postsData = [PixivPost_show]()
        
        var query = PixivPost.postTable.select(
            PixivPost.e_postName,
            PixivPost.e_postFolderName,
            PixivPost.e_postId,
            PixivPost.e_imageNumber,
            PixivPost.e_postDate,
            PixivPost.e_viewed
        ).filter(KemonoPost.e_artistIdRef == artistId)
        query = addQueryConfigFilter(query: query, queryConfig: queryConfig)
        
        if queryConfig.onlyShowNotViewedPost {
            query = query.filter(KemonoPost.e_viewed == false)
        }
        
        do {
            
            for row in try db.prepare(query) {
                let currentPost = PixivPost_show(
                    name: row[PixivPost.e_postName],
                    folderName: row[PixivPost.e_postFolderName],
                    id: row[PixivPost.e_postId],
                    imageNumber: Int(row[PixivPost.e_imageNumber]),
                    postDate: row[PixivPost.e_postDate],
                    viewed: row[PixivPost.e_viewed]
                )
                postsData.append(currentPost)
            }
        } catch {
            print(error.localizedDescription)
        }
        return postsData
    }
    
    static func addQueryConfigFilter(query: SQLite.Table, queryConfig: PixivPostQueryConfig) -> SQLite.Table {
        var outputQuery = query
        switch queryConfig.sortKey {
        case .date:
            outputQuery = outputQuery.order(queryConfig.sortOrder == .ascending ? KemonoPost.e_postDate.asc : KemonoPost.e_postDate.desc)
        case .postTitle:
            outputQuery = outputQuery.order(queryConfig.sortOrder == .ascending ? KemonoPost.e_postName.asc : KemonoPost.e_postName.desc)
        }
        return outputQuery
    }
    
}


