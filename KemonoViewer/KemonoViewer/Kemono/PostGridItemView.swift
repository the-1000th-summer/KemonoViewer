//
//  GridItemView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI
import Kingfisher
import ImageIO
import UniformTypeIdentifiers

struct GridItemMediaView: View {
    let initialSize: Double
    let imageURL: URL?
    
    var body: some View {
        if let imageURL {
            if (imageURL.pathExtension == "psd" || imageURL.pathExtension == "psb") {
                VStack {
                    Image(systemName: "document.fill")
                    Text("Adobe photoshop file")
                }
            } else if (UTType(filenameExtension: imageURL.pathExtension)?.conforms(to: .image)) ?? false {
                KFImage(imageURL)
                    .placeholder { ProgressView() }
                    .onFailureView {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Cover image load failed.")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .setProcessor(ShortSideDownsamplingProcessor(targetShortSide: initialSize))
                    .cacheMemoryOnly(true)
                    .resizable()
                    .scaledToFill()
            } else if imageURL.pathExtension == "ugoira" {
                if let firstImageData = AniImageDecoder.getFirstImageDataFromUgoiraFile(from: imageURL) {
                    KFImage(source: .provider(
                        RawImageDataProvider(data: firstImageData, cacheKey: imageURL.path(percentEncoded: false))
                    ))
                    .setProcessor(ShortSideDownsamplingProcessor(targetShortSide: initialSize))
                    .cacheMemoryOnly(true)
                    .resizable()
                    .scaledToFill()
                } else {
                    EmptyView()
                }
                
            } else {
                Image("custom.document.fill.badge.questionmark")
                    .font(.largeTitle)
                Text("\(imageURL.lastPathComponent)\nNot an image file")
            }
        } else {
            VStack {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.largeTitle)
                Text("No cover image")
            }
        }
    }
}

struct PostGridItemView: View {
    let postData: Post_show
    let size: Double
    let initialSize: Double
    let imageURL: URL?
    let isSelected: Bool
    
    var body: some View {
        Group {
            ZStack(alignment: .topTrailing) {
                GridItemMediaView(initialSize: initialSize, imageURL: imageURL)
                    .frame(width: size, height: size)
                VStack {
                    Text(postData.name)
                        .padding(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Rectangle()
                                .fill(Color.black.opacity(0.7))
                        )
                    Spacer()
                    Text(formatDateStr(dateData: postData.postDate) + "\n" + getAttachmentStr(attachmentNumber: postData.attNumber))
                        .padding(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Rectangle()
                                .fill(Color.black.opacity(0.7))
                        )
                }
                
                Image(systemName: "circlebadge.fill")
                    .padding(.top, 2)
                    .padding(.trailing, 2)
                    .foregroundStyle(.blue)
                    .opacity(postData.viewed ? 0 : 1)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            
        }
    }
    
//    private func getErrorTxt(err: KingfisherError) -> String {
//        switch err.errorCode {
//        case 5003:
//            return "Cover image: \(imageURL.path(percentEncoded: false)) not exists."
//        case 4001:
//            return "Not a valid image file: \(imageURL.lastPathComponent)."
//        default:
//            return "\(err.errorCode)rrr\n" + (err.errorDescription ?? "")
//        }
//    }
    
    private func formatDateStr(dateData: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter.string(from: dateData)
    }
    
    private func getAttachmentStr(attachmentNumber: Int) -> String {
        switch attachmentNumber {
        case 0:
            return "No attachments"
        case 1:
            return "1 attachment"
        default:
            return "\(attachmentNumber) attachments"
        }
    }
    
}

public struct ShortSideDownsamplingProcessor: ImageProcessor {
    public let targetShortSide: CGFloat
    public let identifier: String
    
    public init(targetShortSide: CGFloat) {
        self.targetShortSide = targetShortSide
        self.identifier = "com.onevcat.Kingfisher.ShortSideDownsamplingProcessor(\(targetShortSide))"
    }
    
    public func process(item: Kingfisher.ImageProcessItem, options: Kingfisher.KingfisherParsedOptionsInfo) -> Kingfisher.KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            let originalSize = image.size
            return downsample(
                data: image.kf.data(format: .unknown) ?? Data(),
                originalSize: originalSize,
                scaleFactor: options.scaleFactor
            )
        case .data(let data):
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
                  let height = properties[kCGImagePropertyPixelHeight] as? CGFloat
            else { return nil }
            
            return downsample(
                data: data,
                originalSize: CGSize(width: width, height: height),
                scaleFactor: options.scaleFactor
            )
        }
    }
    
    private func downsample(data: Data, originalSize: CGSize, scaleFactor: CGFloat) -> KFCrossPlatformImage? {
        // 计算原始图片短边
        let originalShortSide = min(originalSize.width, originalSize.height)
        
        // 如果原始短边小于目标值，不需要缩小
//        guard originalShortSide > targetShortSide else {
//            return KingfisherWrapper.image(data: data, options: nil)
//        }
        
        // 计算缩放比例
        let scale = targetShortSide / originalShortSide
        
        // 计算新尺寸 (保持比例)
        let originalLongSide = max(originalSize.width, originalSize.height)
        let targetLongSide = originalLongSide * scale
        
        return KingfisherWrapper.downsampledImage(data: data, to: CGSize(width: targetLongSide, height: targetLongSide), scale: scaleFactor)
        
    }
}

#Preview {
    PostGridItemView(
        postData: Post_show(
            name: "罠にかかった秋月修正", folderName: "[2019-05-12]罠にかかった秋月修正", coverName: "notused.jpg", id: -1, attNumber: 1, postDate: Date(),  viewed: false
        ),
        size: 200,
        initialSize: 200,
        imageURL: URL(filePath: "/Volumes/ACG/kemono/5924557/[2019-05-12]罠にかかった秋月修正/1.jpe"),
        isSelected: true,
    )
}
