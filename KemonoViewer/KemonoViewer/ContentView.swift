//
//  ContentView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack {
            Button("Kemono content") {
                openWindow(id: "viewer")
            }
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
