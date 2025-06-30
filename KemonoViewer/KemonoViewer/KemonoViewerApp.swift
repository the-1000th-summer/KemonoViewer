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
        WindowGroup("my fullScreen window", id: "fsViewer") {
            FullScreenImageView()
        }
    }
}
