//
//  KemonoImageViewItem.swift
//  KemonoViewer
//
//  Created on 2025/6/14.
//

import Cocoa

class KemonoImageViewItem: NSCollectionViewItem {
    
    let selectedBorderThickness: CGFloat = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.borderColor = NSColor.blue.cgColor
    }
    
//    override var isSelected: Bool {
//        didSet {
//            if isSelected {
//                view.layer?.borderWidth = selectedBorderThickness
//                let storyboard = NSStoryboard(name: "Main", bundle: nil)
////                guard let windowController = storyboard.instantiateController(withIdentifier: "fsImageWindowController") as? FullScreenImageWindowController else { return }
////                windowController.showWindow(self)
//            } else {
//                view.layer?.borderWidth = 0
//            }
//        }
//    }
    
//    override var highlightState: NSCollectionViewItem.HighlightState {
//        didSet {
//            if highlightState == .forSelection {
//                view.layer?.borderWidth = selectedBorderThickness
//            } else {
//                if !isSelected {
//                    view.layer?.borderWidth = 0
//                }
//            }
//        }
//    }
    
}
