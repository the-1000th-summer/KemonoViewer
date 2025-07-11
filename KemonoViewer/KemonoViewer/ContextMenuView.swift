//
//  ContextMenuView.swift
//  KemonoViewer
//
//  Created on 2025/7/11.
//

import SwiftUI

struct ContextMenuView: View {
    @ObservedObject var manager: SlideShowManager
    @ObservedObject var playerManager: VideoPlayerManager
    
    let slideTimerAction: () -> Void
    private let timeIntervalList: [TimeInterval] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 60, 90]
    
    var body: some View {
        Menu("幻灯片放映") {
            Button(action: {
                manager.stop()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                        .tint(.primary.opacity(
                            manager.currentInterval == 0 ? 1 : 0
                        ))
                    Text("停止放映")
                }
            }
            
            ForEach(timeIntervalList, id: \.self) { timeIntervalInSecond in
                Button(action: {
                    // 视频已经播放完毕
                    if manager.getMovieCompleted() {
                        manager.start(interval: timeIntervalInSecond) {
                            slideTimerAction()
                        }
                    } else {
                        manager.setIntervalAndAction(interval: timeIntervalInSecond) {
                            slideTimerAction()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                            .tint(.primary.opacity(
                                manager.currentInterval == timeIntervalInSecond ? 1 : 0
                            ))
                        Text("\(Int(timeIntervalInSecond))秒")
                    }
                }
            }
        }
    }
}

//#Preview {
//    ContextMenuView()
//}
