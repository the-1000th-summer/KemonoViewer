//
//  PixivTextContentView.swift
//  KemonoViewer
//
//  Created on 2025/7/30.
//

import SwiftUI
import Kingfisher

struct PixivContent_show {
    let pixivPostId: String
    let postName: String
    let comment: String
    let postDate: Date
    let likeCount: Int
    let bookmarkCount: Int
    let viewCount: Int
    let commentCount: Int
    let xRestrict: Int
    let isHowto: Bool
    let isOriginal: Bool
    let aiType: Int
}

struct PixivCountView: View {
    let systemImageName: String
    let countNumber: Int
    
    var body: some View {
        HStack {
            Image(systemName: systemImageName)
            Text("\(countNumber)")
                .padding(.leading, -5)
        }
        .font(.system(size: 15))
        .foregroundStyle(.gray)
        .padding(.trailing)
    }
}

struct PixivTagView: View {
    let pixivContent: PixivContent_show
    
    var body: some View {
        
    }
}

struct PixivTextContentView: View {
    
    @State private var contentLoading = false
    @State private var pixivContent: PixivContent_show? = nil
    
    @ObservedObject var imagePointer: PixivImagePointer
    
    private static let postDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    @ViewBuilder
    private func contentView(contentStr: String) -> some View {
        if let htmlData = contentStr.data(using: .utf16), let nsAttributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil),
           let attributedString = try? AttributedString(nsAttributedString, including: \.appKit) {
            Text(attributedString)
        } else {
            Text(contentStr)
        }
    }
    
    var body: some View {
        ScrollView {
            if contentLoading {
                HStack{
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        KFImage(imagePointer.getArtistAvatarURL())
                            .cacheMemoryOnly(true)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        
                        Text(imagePointer.getArtistName())
                            .font(.system(size: 15))
                            .fontWeight(.medium)
                    }
                    
                    if let pixivContent {
                        Link(destination: URL(string: "https://www.pixiv.net/artworks/\(pixivContent.pixivPostId)")!) {
                            VStack(alignment: .leading) {
                                Text(pixivContent.postName)
                                    .font(.system(size: 20))
                                    .fontWeight(.medium)
                                contentView(contentStr: String(format:"<span style=\"font-family: '-apple-system', 'HelveticaNeue'; font-size: 15\">%@</span>", pixivContent.comment))
                            }
                        }
                        .foregroundStyle(.foreground)
                        .buttonStyle(PlainButtonStyle())
                        .onHover { isHovering in
                            if isHovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        
                        HStack {
                            PixivCountView(systemImageName: "face.smiling", countNumber: pixivContent.likeCount)
                            PixivCountView(systemImageName: "heart.fill", countNumber: pixivContent.bookmarkCount)
                            PixivCountView(systemImageName: "eye.fill", countNumber: pixivContent.viewCount)
                            PixivCountView(systemImageName: "message.fill", countNumber: pixivContent.commentCount)
                        }
                        .padding(.vertical, 5)
                        
                        Text(PixivTextContentView.postDateFormatter.string(from: pixivContent.postDate))
                            .font(.system(size: 15))
                            .foregroundStyle(.gray)
                    }
                    Divider()
                        .padding(.horizontal)
                    if let pixivContent {
                        PixivCommentView(pixivPostId: pixivContent.pixivPostId)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .padding()
                    }
                }
//                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
            }
        }
        .onAppear {
            loadAllData()
        }
        .onChange(of: imagePointer.currentPostDirURL) {
            loadAllData()
        }
    }
    
    private func loadAllData() {
        contentLoading = true
        Task {
            let loadResult = await imagePointer.loadContentData()
            await MainActor.run {
                pixivContent = loadResult
                contentLoading = false
            }
        }
    }
    
}

//#Preview {
//    PixivTextContentView()
//}
