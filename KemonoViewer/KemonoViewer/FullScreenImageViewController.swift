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
    
    @IBOutlet var imageView: NSImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
//        imageView.wantsLayer = true
//        imageView.layer?.contentsGravity = .resizeAspectFill
//        imageView.layer?.masksToBounds = true // 启用裁剪
    }
    
    func updateImage(imageURL: URL) {
        imageView.image = NSImage(contentsOf: imageURL)
    }
    
}
