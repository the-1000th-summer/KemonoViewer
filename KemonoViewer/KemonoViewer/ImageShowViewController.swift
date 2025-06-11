//
//  ImageShowViewController.swift
//  KemonoViewer
//
//  Created on 2025/6/11.
//

import Cocoa
import SQLite

class ImageShowViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        aa()
    }
    
    func aa() {
        let fm = FileManager.default
        let inputFolderPath = "/Volumes/ACG/kemono"
        do {
            // 获取目录下所有内容的名字（包括文件和文件夹）
            let contents = try fm.contentsOfDirectory(atPath: inputFolderPath, )
            print("目录内容: \(contents)")
        } catch {
            print(error.localizedDescription)
        }
         
        
            
    }
    
    func addDataToDatabase(db: Connection) {
        let kemonoDirPath = "/Volumes/ACG/kemono"
//        let fm = FileManager.default
    }
    
    func initDatabase() {
        let dbFilePath = "/Volumes/imagesShown/images.sqlite3"
        let fm = FileManager.default
        if fm.fileExists(atPath: dbFilePath) {
            return
        }
        
        do {
            let db = try Connection(dbFilePath)
            createTable(db: db)
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func createTable(db: Connection) {
        // artist
        let artistTable = Table("artist")
        let e_artistId = Expression<Int64>("id")
        let e_artistName = Expression<String>("name")
        
        do {
            try db.run(artistTable.create { t in
                t.column(e_artistId, primaryKey: .autoincrement)
                t.column(e_artistName, unique: true)
            })
        } catch {
            print(error.localizedDescription)
            return
        }
        
        // post
        let postTable = Table("kemonoPost")
        let e_postId = Expression<Int64>("id")
        let e_artistIdRef = Expression<Int64>("artist_id")
        let e_postName = Expression<String>("name")
        let e_postDate = Expression<Date>("post_date")
        
        do {
            try db.run(postTable.create { t in
                t.column(e_postId, primaryKey: .autoincrement)
                t.column(e_artistIdRef)
                t.column(e_postName)
                t.column(e_postDate)
                
                t.foreignKey(e_artistIdRef, references: artistTable, e_artistId, delete: .cascade)
            })
            
        } catch {
            print(error.localizedDescription)
            return
        }
        
        // image
        let imageTable = Table("kemonoImage")
        let e_imageId = Expression<Int64>("id")
        let e_postIdRef = Expression<Int64>("post_id")
        let e_imageName = Expression<String>("name")
        let e_viewed = Expression<Bool>("viewed")
        
        do {
            try db.run(imageTable.create { t in
                t.column(e_imageId, primaryKey: .autoincrement)
                t.column(e_postIdRef)
                t.column(e_imageName)
                t.column(e_viewed, defaultValue: false)
                
                t.foreignKey(e_postIdRef, references: postTable, e_postId, delete: .cascade)
            })
            
            try db.execute("PRAGMA foreign_keys = ON")
        } catch {
            print(error.localizedDescription)
            return
        }
        
    }
    
}
