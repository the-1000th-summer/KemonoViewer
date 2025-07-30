//
//  MediaView.swift
//  KemonoViewer
//
//  Created on 2025/7/28.
//

import SwiftUI
import UniformTypeIdentifiers

extension View {
    func onImageLoad(perform action: @escaping () -> Void) -> some View {
        modifier(ImageLoadModifier(action: action))
    }
}

struct ImageLoadModifier: ViewModifier {
    let action: () -> Void
    @State private var didLoad = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !didLoad {
                    action()
                    didLoad = true
                }
            }
    }
}

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
                    slideShowManager: slideManager,
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
                            .onAppear {
                                slideManager.setMovieCompleted(completed: true)
                                slideManager.restart()
                            }
                            .onChange(of: mediaURL) {
                                slideManager.setMovieCompleted(completed: true)
                                slideManager.restart()
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
            AniImagePlayerView_hasControl(
                insideView: $insideView,
                transform: $transform,
                messageManager: messageManager,
                slideShowManager: slideManager,
                inputFileURL: mediaURL
            )
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

