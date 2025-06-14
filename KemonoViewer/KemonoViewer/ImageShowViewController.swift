//
//  ImageShowViewController.swift
//  KemonoViewer
//
//  Created on 2025/6/11.
//

import Cocoa
import SQLite
import SwiftyJSON

class ImageShowViewController: NSViewController {
    
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
    }
    

    
    @IBAction func loadData(_ sender: NSButton) {
        aa()
    }
    
    func aa() {
        let inputFolderPath = "/Volumes/ACG/kemono"
        
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return
        }
        
        guard let artistsName = getSubdirectoryNames(atPath: inputFolderPath) else { return }
        for artistName in artistsName {
            let artistDirPath = URL(filePath: inputFolderPath).appendingPathComponent(artistName).path()
            if let postsName = getSubdirectoryNames(atPath: artistDirPath) {
                var a = 0
                var artistId: Int64? = nil
                
                try! db.transaction {
                    for postName in postsName {
                        let currentPostDirPath = URL(filePath:artistDirPath).appendingPathComponent(postName).path(percentEncoded: false)
                        
                        artistId = handleOnePost(postDirPath: currentPostDirPath, artistId: artistId)
                        a += 1
                        print(a)
                    }
                }
            }
            return
                    
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
        guard let db = DatabaseManager.shared.getConnection() else {
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
            let a = jsonObj["attachments"].arrayValue.count
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
                let fileExt = URL(fileURLWithPath: attachment["name"].stringValue).pathExtension
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
    
    func addDataToDatabase(db: Connection) {
        let kemonoDirPath = "/Volumes/ACG/kemono"
//        let fm = FileManager.default
    }
    
    
    
    
    
}
