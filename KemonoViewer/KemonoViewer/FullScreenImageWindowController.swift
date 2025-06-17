//
//  FullScreenImageWindowController.swift
//  KemonoViewer
//
//  Created on 2025/6/14.
//

import Cocoa

class FullScreenImageWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

        window?.toggleFullScreen(nil)

//        if let vc = contentViewController as? FullScreenImageViewController {
//            vc.configure
//        }
        
    }
    
    func initData(artistName: String, postsFolderName: [String], postsId: [Int64], currentPostImagesName: [String], currentPostIndex: Int, currentImageIndex: Int) {
        if let vc = contentViewController as? FullScreenImageViewController {
            vc.initData(
                artistName: artistName,
                postsFolderName: postsFolderName,
                postsId: postsId,
                currentPostImagesName: currentPostImagesName,
                currentPostIndex: currentPostIndex,
                currentImageIndex: currentImageIndex
            )
        }
    }
    
    func updateImage() {
        if let vc = contentViewController as? FullScreenImageViewController {
            vc.updateImage()
        }
    }

}
