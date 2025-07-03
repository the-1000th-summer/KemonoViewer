//
//  ContentView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct HoverView: View {
    @State private var isHovering = false  // 悬停状态标记
    
    var body: some View {
        // 主容器（悬停区域）
        Rectangle()
            .fill(Color.blue)
            .frame(width: 200, height: 100)
            .cornerRadius(10)
            .onHover { hovering in
                isHovering = hovering  // 鼠标进入/离开时更新状态
            }
            .overlay(
                // 条件显示悬浮提示视图
                hoverOverlayView
            )
    }
    
    // 鼠标悬停时显示的视图
    private var hoverOverlayView: some View {
        Group {
            if isHovering {
                Text("Hello! 👋")
                    .padding(10)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .shadow(radius: 3)
                    .transition(.opacity)  // 添加淡入淡出效果
            }
        }
        .animation(.easeInOut, value: isHovering) // 平滑动画
    }
}

// 预览
#Preview {
    HoverView()
        .frame(width: 300, height: 200)
}

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
//    ContentView()
    HoverView()
}
