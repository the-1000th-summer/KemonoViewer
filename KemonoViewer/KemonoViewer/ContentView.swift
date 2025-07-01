//
//  ContentView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct SymbolTabView: View {
    // 定义选项卡枚举，关联普通和填充版本的 SF Symbol
    enum Tab: String, CaseIterable {
        case home
        case favorites
        case search
        case settings
        
        // 普通图标名称
        var icon: String {
            switch self {
            case .home: return "house"
            case .favorites: return "heart"
            case .search: return "magnifyingglass"
            case .settings: return "gear"
            }
        }
        
        // 填充版本图标名称
        var fillIcon: String {
            return icon + ".fill"
        }
        
        // 标签文本
        var label: String {
            switch self {
            case .home: return "首页"
            case .favorites: return "收藏"
            case .search: return "搜索"
            case .settings: return "设置"
            }
        }
        
        // 关联的颜色
        var color: Color {
            switch self {
            case .home: return .blue
            case .favorites: return .pink
            case .search: return .orange
            case .settings: return .gray
            }
        }
    }
    
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        VStack(spacing: 0) {
            // 内容区域
            Group {
                switch selectedTab {
                case .home: contentView(title: "首页", color: .blue)
                case .favorites: contentView(title: "收藏夹", color: .pink)
                case .search: contentView(title: "搜索", color: .orange)
                case .settings: contentView(title: "设置", color: .gray)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 自定义标签栏
            HStack {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack {
                            // 动态切换填充/非填充图标
                            Image(systemName: selectedTab == tab ? tab.fillIcon : tab.icon)
                                .font(.system(size: 22, weight: .semibold))
                            
                        }
                        .foregroundColor(selectedTab == tab ? tab.color : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // 用于指示器的动画
    @Namespace private var animation
    
    // 内容视图生成器
    private func contentView(title: String, color: Color) -> some View {
        VStack {
            Text(title)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(color.gradient)
            
            Text("当前选中：\(selectedTab.label)")
                .font(.title3)
                .padding(.top, 10)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
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
    SymbolTabView()
}
