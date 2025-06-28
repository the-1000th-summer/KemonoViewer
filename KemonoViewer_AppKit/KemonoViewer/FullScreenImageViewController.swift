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

class FullScreenImageViewController: NSViewController, KeyboardDelegate {
    
    var showImage: [NSImage] = []
    var imagePointer: ImagePointer?
    
    private var hideTextFieldTimer: Timer?
    
    @IBOutlet var fullScreenView: FullScreenView!
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var pathTextField: NSTextField!
    @IBOutlet var errorMsgLabel: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
//        imageView.wantsLayer = true
//        imageView.layer?.contentsGravity = .resizeAspectFill
//        imageView.layer?.masksToBounds = true // 启用裁剪
        fullScreenView.delegate = self
        pathTextField.stringValue = "/Volumes/ACG/[Hills] "
        pathTextField.sizeToFit()
    }
    
    @IBAction func previousBtnClicked(_ sender: NSButton) {
        showPreviousImage()
    }
    
    @IBAction func nextBtnClicked(_ sender: NSButton) {
        showNextImage()
    }
    
    open override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }
    
    func handleKeyDown(_ event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "]" {
                showNextImage()
            } else if event.charactersIgnoringModifiers == "[" {
                showPreviousImage()
            }
        }
    }
    
    private func showPreviousImage() {
        errorMsgLabel.isHidden = true
        let (currentImageURL, previousPostDirURL) = imagePointer!.getPreviousImageURL()
        if let currentImageURL {
            if let currentImage = NSImage(contentsOf: currentImageURL) {
                imageView.image = currentImage
            } else {
                imageView.image = nil
                errorMsgLabel.isHidden = false
                errorMsgLabel.stringValue = "文件缺失：\n" + currentImageURL.path(percentEncoded: false)
            }
        } else {
            imageView.image = nil
        }
        if let previousPostDirURL {
            showStatusMessage("上一个文件夹：\n" + previousPostDirURL.path(percentEncoded: false))
        }
        if currentImageURL == nil && previousPostDirURL != nil {
            errorMsgLabel.isHidden = false
            errorMsgLabel.stringValue = "无附件"
        }
    }
    private func showNextImage() {
        errorMsgLabel.isHidden = true
        let (currentImageURL, nextPostDirURL) = imagePointer!.getNextImageURL()
        if let currentImageURL {
            if let currentImage = NSImage(contentsOf: currentImageURL) {
                imageView.image = currentImage
            } else {
                imageView.image = nil
                errorMsgLabel.isHidden = false
                errorMsgLabel.stringValue = "文件缺失：\n" + currentImageURL.path(percentEncoded: false)
            }
        } else {
            imageView.image = nil
        }
        if let nextPostDirURL {
            showStatusMessage("下一个文件夹：\n" + nextPostDirURL.path(percentEncoded: false))
        }
        if currentImageURL == nil && nextPostDirURL != nil {
            errorMsgLabel.isHidden = false
            errorMsgLabel.stringValue = "无附件"
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
    
    private func showStatusMessage(_ message: String, duration: TimeInterval = 1.0) {
        // 取消之前的计时器
        hideTextFieldTimer?.invalidate()
        
        // 更新文本
        pathTextField.stringValue = message
        pathTextField.sizeToFit() // 调整大小以适应文本
        
        // 显示文本字段
        pathTextField.isHidden = false
        
        // 创建新的计时器（1秒后隐藏）
        hideTextFieldTimer = Timer.scheduledTimer(
            withTimeInterval: duration,
            repeats: false
        ) { [weak self] _ in
            self?.pathTextField.isHidden = true
        }
    }
    
}

protocol KeyboardDelegate: AnyObject {
    func handleKeyDown(_ event: NSEvent)
}
