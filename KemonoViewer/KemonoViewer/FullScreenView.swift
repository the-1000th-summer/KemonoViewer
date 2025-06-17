//
//  FullScreenView.swift
//  KemonoViewer
//
//  Created on 2025/6/16.
//

import Cocoa

class FullScreenView: NSView {
    
    weak var delegate: KeyboardDelegate?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    open override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        delegate?.handleKeyDown(event)
    }
    
}
