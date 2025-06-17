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
    
    private var imagesName = [String]()
    private var postDirPath = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesName.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("KemonoImageViewItem"), for: indexPath)
        guard let pictureItem = item as? KemonoImageViewItem else { return item }
        
        
        let imageURL = URL(filePath: postDirPath).appendingPathComponent(imagesName[indexPath.item])
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
        imagesName.removeAll()
        self.postDirPath = postDirPath
        
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return
        }
        do {
            let query = KemonoImage.imageTable.select(KemonoImage.e_imageName).filter(KemonoImage.e_postIdRef == postId)
            for row in try db.prepare(query) {
                imagesName.append(row[KemonoImage.e_imageName])
//                postsId.append(row[KemonoPost.e_postId])
            }
        } catch {
            print(error.localizedDescription)
        }
        imageCollectionView.reloadData()
        
//        kemonoImageView.image = NSImage(named: name)
    }
    
    func deselectPost() {
        imagesName.removeAll()
        postDirPath.removeAll()
        imageCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
//        let imageURL = URL(filePath: postDirPath).appendingPathComponent(imagesName[indexPaths.first!.item])
        
        guard let splitVC = parent as? NSSplitViewController, let artistTVC = splitVC.children[0] as? ArtistTableViewController, let postTVC = splitVC.children[1] as? PostTableViewController else { return }
        
        guard let windowController = storyboard?.instantiateController(withIdentifier: "fsImageWindowController") as? FullScreenImageWindowController else { return }
        windowController.showWindow(self)
        windowController.initData(
            artistName: artistTVC.getSelectedArtistName(),
            postsFolderName: postTVC.getPostsFolderName(),
            postsId: postTVC.getPostsId(),
            currentPostImagesName: imagesName,
            currentPostIndex: postTVC.getSelectedPostIndex(),
            currentImageIndex: indexPaths.first!.item
        )
        windowController.updateImage()
    }
    
}
