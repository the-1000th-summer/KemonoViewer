//
//  PixivDatabaseManager.swift
//  KemonoViewer
//
//  Created on 2025/7/23.
//

import Foundation
import SQLite


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
    
    
    
}

final class PixivDataReader {
    static func readArtistData(queryConfig: ArtistQueryConfig) async -> [KemonoArtist_show]? {
        guard let db = KemonoDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        
        var sqlStr = """
        SELECT
          a."name",
          a."member_id",
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
    }
}


