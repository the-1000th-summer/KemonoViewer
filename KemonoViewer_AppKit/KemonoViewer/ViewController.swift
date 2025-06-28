//
//  ViewController.swift
//  KemonoViewer
//
//  Created on 2025/6/11.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func tryButtonAction(_ sender: NSButton) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let windowController = storyboard.instantiateController(withIdentifier: "fsImageWindowController") as? FullScreenImageWindowController else { return }
        windowController.showWindow(self)
    }
    
}

