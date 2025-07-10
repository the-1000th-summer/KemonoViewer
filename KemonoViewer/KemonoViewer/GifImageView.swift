//
//  GifImageView.swift
//  KemonoViewer
//
//  Created on 2025/7/9.
//

import SwiftUI
import WebKit

struct GifImageView: NSViewRepresentable {
    
    private let imageURL: URL
    
    init(imageURL: URL) {
        self.imageURL = imageURL
    }
    
    func makeNSView(context: Context) -> some NSView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        let data = try! Data(contentsOf: imageURL)
        (nsView as? WKWebView)?.load(data, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: imageURL.deletingLastPathComponent())
    }
    

}

struct GIFImageView2: NSViewRepresentable {
    let gifURL: URL

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.canDrawSubviewsIntoLayer = true
        view.animates = true
        view.imageScaling = .scaleProportionallyUpOrDown
        return view
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        if let data = try? Data(contentsOf: gifURL),
           let image = NSImage(data: data) {
            nsView.image = image
        }
    }
}

struct GIFView: NSViewRepresentable {
    let url: URL
//    var width: CGFloat?
//    var height: CGFloat?
    
    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyDown
        
        // 异步加载 GIF
        loadGIF(from: url) { gifImage in
            DispatchQueue.main.async {
                imageView.image = gifImage
            }
        }
        
        return imageView
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        // 更新时重新加载 GIF
        loadGIF(from: url) { gifImage in
            DispatchQueue.main.async {
                nsView.image = gifImage
            }
        }
    }
    
    // 加载 GIF 并创建动画图像
    private func loadGIF(from url: URL, completion: @escaping (NSImage?) -> Void) {
        DispatchQueue.global().async {
            // 1. 获取 GIF 数据
            let data: Data?
            if url.isFileURL {
                data = try? Data(contentsOf: url) // 本地文件
            } else {
                data = try? Data(contentsOf: url) // 网络请求（实际项目中应使用 URLSession）
            }
            
            guard let gifData = data else {
                completion(nil)
                return
            }
            
            // 2. 解析 GIF 帧
            guard let source = CGImageSourceCreateWithData(gifData as CFData, nil),
                  let frameDurations = GIFView.frameDurations(from: source) else {
                completion(NSImage(data: gifData))
                return
            }
            
            // 3. 创建动画图像
            let animatedImage = NSImage()
            var totalDuration = 0.0
            
            for i in 0..<CGImageSourceGetCount(source) {
                if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    let frameImage = NSImage(cgImage: cgImage, size: .zero)
                    animatedImage.addRepresentation(frameImage.representations.first!)
                    
                    // 设置帧属性
//                    let frameProps = [
//                        NSImage.PropertyKey.loopCount: 0,  // 无限循环
//                        NSImage.PropertyKey.duration: frameDurations[i]
//                    ] as [NSImage.PropertyKey : Any]
                    
//                    frameImage.setProperty(.gifDictionary, withValue: frameProps)
                }
                totalDuration += frameDurations[i]
            }
            
            // 4. 设置全局动画属性
//            let gifProperties: [NSImage.PropertyKey: Any] = [
//                .loopCount: 0,
//                .frameCount: frameDurations.count,
//                .currentFrameDuration: totalDuration
//            ]
            
//            animatedImage.setProperty(.gifDictionary, withValue: gifProperties)
            completion(animatedImage)
        }
    }
    
    // 解析每帧持续时间
    private static func frameDurations(from source: CGImageSource) -> [Double]? {
        let frameCount = CGImageSourceGetCount(source)
        var durations = [Double]()
        
        for i in 0..<frameCount {
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
                  let gifDict = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
                return nil
            }
            
            // 获取帧延迟时间（秒）
            let delayTime = gifDict[kCGImagePropertyGIFDelayTime] as? Double ?? 0.1
            durations.append(delayTime)
        }
        
        return durations
    }
}

#Preview {
    GifImageView(imageURL: URL(filePath: "/Volumes/ACG/kemono/Makoda/[2023-04-07]Kamisato Ayaka gif/1.gif"))
        .frame(width: 2000, height: 1000)
}
