//
//  KemonoViewerApp.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

@main
struct KemonoViewerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Window("my kemono window", id: "viewer") {
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
        
        WindowGroup("my fullScreen window", id: "fsViewer", for: ImagePointerData.self) { $imagePointerData in
            if let imagePointerData {
                FullScreenImageView(imagePointerData: imagePointerData)
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
    }
}
