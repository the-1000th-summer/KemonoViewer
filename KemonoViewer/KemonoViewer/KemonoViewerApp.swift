//
//  KemonoViewerApp.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

@main
struct KemonoViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Window("my Main Window", id: "mainWindow") {
            ContentView()
        }
        
        Settings {
            SettingsView()
        }
        
        Window("my kemono window", id: "kemonoViewer") {
            KContentSelectView()
        }
        Window("my twitter window", id: "twitterViewer") {
            TwitterContentView()
        }
        Window("my pixiv window", id: "pixivViewer") {
            PixivContentView()
        }
        Window("my kemono renamer", id: "renamer") {
            RenamerView()
        }
        
        WindowGroup("my kemono fullScreen window", id: "fsViewer", for: KemonoImagePointerData.self) { $imagePointerData in
            if let imagePointerData {
                KemonoFullScreenImageView(imagePointerData: imagePointerData)
            } else {
                Text("lack of image pointer data")
            }
        }
        WindowGroup("my twitter fullScreen window", id: "twitterFsViewer", for: TwitterImagePointerData.self) { $imagePointerData in
            if let imagePointerData {
                TwitterFullScreenImageView(imagePointerData: imagePointerData)
            } else {
                Text("lack of image pointer data")
            }
        }
        WindowGroup("my pixiv fullScreen window", id: "pixivFsViewer", for: PixivImagePointerData.self) {  $imagePointerData in
            if let imagePointerData {
                PixivFullScreenImageView(imagePointerData: imagePointerData)
            } else {
                Text("lack of image pointer data")
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
