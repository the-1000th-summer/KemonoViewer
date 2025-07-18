//
//  PostImageGridItemView.swift
//  KemonoViewer
//
//  Created on 2025/7/2.
//

import SwiftUI
import Kingfisher
import UniformTypeIdentifiers
import QuickLookThumbnailing


struct ThumbnailImageView: View {
    let url: URL
    let initialSize: Double

    @State private var thumbnail: CGImage? = nil

    var body: some View {
        Group {
            if thumbnail != nil {
                ZStack {
                    Image(self.thumbnail!, scale: NSScreen.main!.backingScaleFactor, label: Text("PDF"))
                        .resizable()
                        .scaledToFill()
                    Image(systemName: "play.circle.fill")
                        .font(.largeTitle)
                }
            } else {
                ProgressView()
                  .onAppear(perform: generateThumbnail)
            }
        }
    }

    private func generateThumbnail() {
        let size: CGSize = CGSize(width: initialSize, height: initialSize)
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: NSScreen.main!.backingScaleFactor, representationTypes: .thumbnail)
        let generator = QLThumbnailGenerator.shared
        
        generator.generateRepresentations(for: request) { (thumbnail, type, error) in
            DispatchQueue.main.async {
                if thumbnail == nil || error != nil {
                    
                    assert(false, "Thumbnail failed to generate")
                } else {
                    DispatchQueue.main.async { // << required !!
                        self.thumbnail = thumbnail!.cgImage  // here !!
                    }
                }
            }
        }
    }
}

struct PostImageGridItemView: View {
    let size: Double
    let imageURL: URL
    @State private var loadPsdFile = false
    
    var body: some View {
//        AsyncImage(url: imageURL) { phase in
//            if let image = phase.image {
//                image
//                    .resizable()
//                    .scaledToFill()
//            } else if phase.error != nil {
//                Text(phase.error!.localizedDescription)
//            } else {
//                ProgressView()  // Acts as a placeholder.
//            }
//        }
        Group {
            if ((imageURL.pathExtension == "psd" || imageURL.pathExtension == "psb")) && !loadPsdFile {
                VStack {
                    Image(systemName: "document.fill")
                    Text("Adobe photoshop file")
                    Button("load") {
                        loadPsdFile = true
                    }
                }
                .frame(width: size, height: size)
            } else if ((UTType(filenameExtension: imageURL.pathExtension)?.conforms(to: .image)) ?? false) {
                KFImage(imageURL)
//                    .placeholder { ProgressView() }
                    .onFailureView {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Image load failed.")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
//                    .setProcessor(ShortSideDownsamplingProcessor(targetShortSide: 300))
                    .cacheMemoryOnly(true)
                    .memoryCacheExpiration(.expired) // no cache
                    .diskCacheExpiration(.expired)   // no cache
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
            } else if (UTType(filenameExtension: imageURL.pathExtension)?.conforms(to: .movie) ?? false) {
                ZStack {
                    ThumbnailImageView(url: imageURL, initialSize: size)
                        .frame(width: size, height: size)
                }
                
            } else {
                VStack {
                    Image("custom.document.fill.badge.questionmark")
                        .font(.largeTitle)
                    Text("\(imageURL.lastPathComponent)\nNot an image file")
                }
                .frame(width: size, height: size)
            }
            
        }
        
    }
    
    private func getErrorTxt(err: KingfisherError) -> String {
        switch err.errorCode {
        case 5003:
            return "File: \(imageURL.lastPathComponent) not exists."
        case 4001:
            return "Not a valid image file: \(imageURL.lastPathComponent)."
        default:
            return "\(err.errorCode)rrr\n" + (err.errorDescription ?? "")
        }
    }
}

extension KingfisherError {
    public var errorDes2: String {
        switch self {
        case .imageSettingError(let reason): return reason.errorDesc2
        default:
            return "not handled error"
        }
    }
}

extension KingfisherError.ImageSettingErrorReason {
    var errorDesc2: String {
        switch self {
        case .dataProviderError(_, let error):
            return "\(error.localizedDescription)"
        default:
            return "not handled error"
        }
    }
}

#Preview {
    PostImageGridItemView(size: 200, imageURL: URL(filePath: "/Volumes/ACG/kemono/flou/[2019-02-06]Vlasé (Hair)  wip  preview/3.mp4"))
//    "/Volumes/ACG/kemono/flou/[2019-02-06]Vlasé (Hair)  wip  preview/3.mp4"
//    "/Volumes/ACG/kemono/5924557/[2019-05-12]罠にかかった秋月修正/1.jpe"
}
