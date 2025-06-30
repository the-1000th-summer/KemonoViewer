//
//  FullScreenImageView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct FullScreenImageView: View {
//    @State private var width: CGFloat? = 800
//    @State private var height: CGFloat? = 600
    
    var body: some View {
        Text("Hello, World!")
            .onAppear {
                if let window = NSApplication.shared.keyWindow {
                                window.toggleFullScreen(nil)
                            }
            }
    }
}

#Preview {
    FullScreenImageView()
}
