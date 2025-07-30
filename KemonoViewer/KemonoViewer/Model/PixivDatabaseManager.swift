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
    static let e_postComment = Expression<String>("comment")
    static let e_postDate = Expression<Date>("post_date")
    static let e_postFolderName = Expression<String>("post_folder_name")
    static let e_coverName = Expression<String>("cover_name")
    static let e_imageNumber = Expression<Int64>("image_number")
    static let e_xRestrict = Expression<Int64>("x_restrict")
    
    static let e_likeCount = Expression<Int64>("like_count")
    static let e_bookmarkCount = Expression<Int64>("bookmark_count")
    static let e_viewCount = Expression<Int64>("view_count")
    static let e_commentCount = Expression<Int64>("comment_count")
    static let e_isHowto = Expression<Bool>("is_howto")
    static let e_isOriginal = Expression<Bool>("is_original")
    static let e_aiType = Expression<Int64>("ai_type")
    
    static let e_viewed = Expression<Bool>("viewed")
}

struct PixivImage {
    static let imageTable = Table("pixivImage")
    static let e_imageId = Expression<Int64>("id")
    static let e_postIdRef = Expression<Int64>("post_id")
    static let e_imageName = Expression<String>("name")
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
    
    func tagPost(postId: Int64, viewed: Bool) async {
        do {
            try db?.run(PixivPost.postTable.filter(PixivPost.e_postId == postId).update(PixivPost.e_viewed <- viewed))
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
          a."avatar_name",
          a."background_name",
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
                    avatarName: row[3] as! String,
                    backgroundName: row[4] as! String,
                    hasNotViewed: (row[6] as! Int64 == 1),
                    id: row[5] as! Int64
                )
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    static func readPostsData(postsId: [Int64], queryConfig: PixivPostQueryConfig) -> [PixivPost_show]? {
        guard let db = PixivDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        
        var query = PixivPost.postTable.select(
            PixivPost.e_postName,
            PixivPost.e_postFolderName,
            PixivPost.e_coverName,
            PixivPost.e_postId,
            PixivPost.e_imageNumber,
            PixivPost.e_postDate,
            PixivPost.e_xRestrict,
            PixivPost.e_viewed
        ).filter(postsId.contains(PixivPost.e_postId))
        query = addQueryConfigFilter(query: query, queryConfig: queryConfig)
        
        do {
            return try db.prepare(query).map {
                PixivPost_show(
                    name: $0[PixivPost.e_postName],
                    folderName: $0[PixivPost.e_postFolderName],
                    coverName: $0[PixivPost.e_coverName],
                    id: $0[PixivPost.e_postId],
                    imageNumber: Int($0[PixivPost.e_imageNumber]),
                    postDate: $0[PixivPost.e_postDate],
                    xRestrict: Int($0[PixivPost.e_xRestrict]),
                    viewed: $0[PixivPost.e_viewed]
                )
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    static func readPostData(artistId: Int64, queryConfig: PixivPostQueryConfig) -> [PixivPost_show]? {
        guard let db = PixivDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        
        var query = PixivPost.postTable.select(
            PixivPost.e_postName,
            PixivPost.e_postFolderName,
            PixivPost.e_coverName,
            PixivPost.e_postId,
            PixivPost.e_imageNumber,
            PixivPost.e_postDate,
            PixivPost.e_xRestrict,
            PixivPost.e_viewed
        ).filter(KemonoPost.e_artistIdRef == artistId)
        query = addQueryConfigFilter(query: query, queryConfig: queryConfig)
        
        if queryConfig.onlyShowNotViewedPost {
            query = query.filter(KemonoPost.e_viewed == false)
        }
        
        do {
            return try db.prepare(query).map {
                PixivPost_show(
                    name: $0[PixivPost.e_postName],
                    folderName: $0[PixivPost.e_postFolderName],
                    coverName: $0[PixivPost.e_coverName],
                    id: $0[PixivPost.e_postId],
                    imageNumber: Int($0[PixivPost.e_imageNumber]),
                    postDate: $0[PixivPost.e_postDate],
                    xRestrict: Int($0[PixivPost.e_xRestrict]),
                    viewed: $0[PixivPost.e_viewed]
                )
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    static func readImageData_async(postId: Int64) async -> [String]? {
        return readImageData(postId: postId)
    }
    
    static func readImageData(postId: Int64) -> [String]? {
        guard let db = PixivDatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return nil
        }
        
        let imageNameQuery = PixivImage.imageTable.select(PixivImage.e_imageName).filter(PixivImage.e_postIdRef == postId)
        
        do {
            return try db.prepare(imageNameQuery).map {
                $0[PixivImage.e_imageName]
            }
        } catch {
            print(error)
        }
        return nil
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


