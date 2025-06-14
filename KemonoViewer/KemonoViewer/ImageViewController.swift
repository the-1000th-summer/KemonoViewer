//
//  ImageViewController.swift
//  KemonoViewer
//
//  Created on 2025/6/14.
//

import Cocoa
import SQLite

class ImageViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    
    @IBOutlet var imageCollectionView: NSCollectionView!
    
    private var imageNames = [String]()
    private var postDirPath = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("KemonoImageViewItem"), for: indexPath)
        guard let pictureItem = item as? KemonoImageViewItem else { return item }
        
        
        let imageURL = URL(filePath: postDirPath).appendingPathComponent(imageNames[indexPath.item])
//        let imageFilePath = imageURL.path(percentEncoded: false)
        print("-", terminator: "")
        let image = NSImage(contentsOf: imageURL)
        print(indexPath.item, terminator: " ")
//        pictureItem.view.wantsLayer = true
//        pictureItem.view.layer?.backgroundColor = NSColor.red.cgColor
        
        pictureItem.imageView?.image = image
        
        
        return pictureItem
    }
    
    func postSelected(postId: Int64, postDirPath: String) {
        imageNames.removeAll()
        self.postDirPath = postDirPath
        
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return
        }
        print("loading image...")
        do {
            let query = KemonoImage.imageTable.select(KemonoImage.e_imageName).filter(KemonoImage.e_postIdRef == postId)
            for row in try db.prepare(query) {
                imageNames.append(row[KemonoImage.e_imageName])
//                postsId.append(row[KemonoPost.e_postId])
            }
        } catch {
            print(error.localizedDescription)
        }
        print("loaded image")
        imageCollectionView.reloadData()
        
//        kemonoImageView.image = NSImage(named: name)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let imageURL = URL(filePath: postDirPath).appendingPathComponent(imageNames[indexPaths.first!.item])
        guard let windowController = storyboard?.instantiateController(withIdentifier: "fsImageWindowController") as? FullScreenImageWindowController else { return }
        windowController.showWindow(self)
        windowController.updateImage(imageURL: imageURL)
    }
    
}
