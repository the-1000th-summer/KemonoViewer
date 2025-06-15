//
//  FullScreenImageViewController.swift
//  KemonoViewer
//
//  Created on 2025/6/14.
//

import Cocoa

open class MyAspectFillImageNSImageView : NSImageView {
    
    open override var image: NSImage? {
        set {
            self.layer = CALayer()
            self.layer?.contentsGravity = .resizeAspectFill
            self.layer?.contents = newValue
            self.wantsLayer = true
            
            super.image = newValue
        }
        
        get {
            return super.image
        }
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    //the image setter isn't called when loading from a storyboard
    //manually set the image if it is already set
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        
        if let theImage = image {
            self.image = theImage
        }
    }
    
}

class FullScreenImageViewController: NSViewController {
    
    var showImage: [NSImage] = []
    var imagePointer: ImagePointer?
    
    @IBOutlet var imageView: NSImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
//        imageView.wantsLayer = true
//        imageView.layer?.contentsGravity = .resizeAspectFill
//        imageView.layer?.masksToBounds = true // 启用裁剪
    }
    
    @IBAction func previousBtnClicked(_ sender: NSButton) {
        if let currentImageURL = imagePointer!.getPreviousImageURL() {
            imageView.image = NSImage(contentsOf: currentImageURL)
        } else {
            imageView.image = nil
        }
        
    }
    
    @IBAction func nextBtnClicked(_ sender: NSButton) {
        if let currentImageURL = imagePointer!.getNextImageURL() {
            imageView.image = NSImage(contentsOf: currentImageURL)
        } else {
            imageView.image = nil
        }
        
    }
    
    func initData(artistName: String, postsFolderName: [String], postsId: [Int64], currentPostImagesName: [String], currentPostIndex: Int, currentImageIndex: Int) {
        imagePointer = ImagePointer(
            artistName: artistName,
            postsFolderName: postsFolderName,
            postsId: postsId,
            currentPostImagesName: currentPostImagesName,
            currentPostIndex: currentPostIndex,
            currentImageIndex: currentImageIndex
        )
    }
    
    func updateImage() {
        imageView.image = NSImage(contentsOf: imagePointer!.getCurrentImageURL())
    }
    
}
