//
//  TwitterDatabaseManager.swift
//  KemonoViewer
//
//  Created on 2025/7/20.
//

import Foundation
import SQLite

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
        let dbFilePath = Constants.twitterDatabaseFilePath
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
                  FROM "twitterImage"
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
    
    private static func getSortItemExpression(sortKey: TwitterImageQueryConfig.SortKey) -> any ExpressionType {
        switch sortKey {
        case .date:
            return TwitterImage.e_tweetDate
        case .tweetContent:
            return TwitterImage.e_content
        case .favoriteCount:
            return TwitterImage.e_favoriteCount
        case .retweetCount:
            return TwitterImage.e_retweetCount
        case .replyCount:
            return TwitterImage.e_replyCount
        }
    }
    
    private static func returnData(query: Table, sortItemExpression: any ExpressionType) -> [TwitterImage_show]? {
        guard let db = TwitterDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        do {
            if let sortItemExp_String = sortItemExpression as? SQLite.Expression<String> {
                return try db.prepare(query).map {
                    TwitterImage_show(
                        id: $0[TwitterImage.e_imageId],
                        name: $0[TwitterImage.e_imageName],
                        viewed: $0[TwitterImage.e_viewed],
                        sortItem: $0[sortItemExp_String]
                    )
                }
            }
            if let sortItemExp_Int64 = sortItemExpression as? SQLite.Expression<Int64> {
                return try db.prepare(query).map {
                    TwitterImage_show(
                        id: $0[TwitterImage.e_imageId],
                        name: $0[TwitterImage.e_imageName],
                        viewed: $0[TwitterImage.e_viewed],
                        sortItem: String($0[sortItemExp_Int64])
                    )
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    static func readImageData(imagesId: [Int64], queryConfig: TwitterImageQueryConfig) -> [TwitterImage_show]? {
        
        var query = TwitterImage.imageTable.filter(imagesId.contains(TwitterImage.e_imageId))
        
        let sortItemExpression = getSortItemExpression(sortKey: queryConfig.sortKey)
        
        query = query.order(queryConfig.sortOrder == .ascending ? sortItemExpression.expression.asc : sortItemExpression.expression.desc)
        query = query.select(TwitterImage.e_imageId, TwitterImage.e_imageName, TwitterImage.e_viewed, sortItemExpression)

        return returnData(query: query, sortItemExpression: sortItemExpression)

    }

    static func readImageData(artistId: Int64, queryConfig: TwitterImageQueryConfig) -> [TwitterImage_show]? {
        
        var query = TwitterImage.imageTable.filter(TwitterImage.e_artistIdRef == artistId)
        
        let sortItemExpression = getSortItemExpression(sortKey: queryConfig.sortKey)
        
        if queryConfig.onlyShowNotViewedPost {
            query = query.filter(TwitterImage.e_viewed == false)
        }
        
        query = query.order(queryConfig.sortOrder == .ascending ? sortItemExpression.expression.asc : sortItemExpression.expression.desc)
        query = query.select(TwitterImage.e_imageId, TwitterImage.e_imageName, TwitterImage.e_viewed, sortItemExpression)
        
        return returnData(query: query, sortItemExpression: sortItemExpression)
    }
    
    static func readImageData_async(artistId: Int64, queryConfig: TwitterImageQueryConfig) async -> [TwitterImage_show]? {
        return readImageData(artistId: artistId, queryConfig: queryConfig)
    }

}
