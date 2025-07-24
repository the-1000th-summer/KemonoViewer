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
                    pixivId: row[1] as! String,
                    hasNotViewed: (row[3] as! Int64 == 1),
                    id: row[2] as! Int64
                )
            }
        } catch {
            print(error)
        }
        return nil
    }
}


