//
//  MediaView.swift
//  KemonoViewer
//
//  Created on 2025/7/28.
//

import SwiftUI
import UniformTypeIdentifiers

struct MediaView: View {
    
    let mediaURL: URL
    @State private var transform = Transform()
    @State private var fileNotFoundPresented = false
    
    @Binding var insideView: Bool
    
    @ObservedObject var messageManager: StatusMessageManager
    @ObservedObject var slideManager: SlideShowManager
    @ObservedObject var playerManager: VideoPlayerManager
    
    var body: some View {
        if (UTType(filenameExtension: mediaURL.pathExtension)?.conforms(to: .image) ?? false) {
            if (UTType(filenameExtension: mediaURL.pathExtension)?.conforms(to: .gif) ?? false) {
                AniImagePlayerView_hasControl(
                    insideView: $insideView,
                    transform: $transform,
                    messageManager: messageManager,
                    inputFileURL: mediaURL
                )
            } else {
                AsyncImage(url: mediaURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .resizableView(insideView: $insideView, transform: $transform, messageManager: messageManager)
                            .onChange(of: mediaURL) {
                                withAnimation(.easeIn(duration: 0.2)) {
                                    transform = Transform()
                                }
                            }
                    } else if phase.error != nil {
                        VStack {
                            Image(systemName: "photo.badge.exclamationmark")
                            Text("Error: " + phase.error!.localizedDescription)
                        }
                        .font(.largeTitle)
                    } else {
                        ProgressView()  // Acts as a placeholder.
                    }
                }
            }
        } else if (UTType(filenameExtension: mediaURL.pathExtension)?.conforms(to: .movie) ?? false) {
            CustomPlayerView(url: mediaURL, slideShowManager: slideManager, playerManager: playerManager) {
                slideManager.setMovieCompleted(completed: true)
                slideManager.restart()
            }
            .resizableView(insideView: $insideView, transform: $transform, messageManager: messageManager)
        } else if mediaURL.pathExtension == "ugoira" {
            AniImagePlayerView_hasControl(insideView: $insideView, transform: $transform, messageManager: messageManager, inputFileURL: mediaURL)
        } else {
            VStack {
                Image("custom.document.fill.badge.questionmark")
                    .font(.largeTitle)
                Text("\(mediaURL.lastPathComponent)\nNot an image file")
                Button("Show in Finder") {
                    if UtilFunc.localFileExists(at: mediaURL) {
                        NSWorkspace.shared.activateFileViewerSelecting([mediaURL])
                    } else {
                        fileNotFoundPresented = true
                    }
                }.popover(isPresented: $fileNotFoundPresented, arrowEdge: .bottom) {
                    Text("File not found in local filesystem.")
                        .padding()
                }
            }
        }
    }
}

