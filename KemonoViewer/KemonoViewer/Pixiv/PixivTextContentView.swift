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
                        Text(pixivContent.postName)
                            .font(.system(size: 20))
                            .fontWeight(.medium)
                        
                        HStack {
                            PixivCountView(systemImageName: "face.smiling", countNumber: pixivContent.likeCount)
                            PixivCountView(systemImageName: "heart.fill", countNumber: pixivContent.bookmarkCount)
                            PixivCountView(systemImageName: "eye.fill", countNumber: pixivContent.viewCount)
                            PixivCountView(systemImageName: "message.fill", countNumber: pixivContent.commentCount)
                        }
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                Divider()
                    .padding(.horizontal)
                if let pixivContent {
                    PixivCommentView(pixivPostId: pixivContent.pixivPostId)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .onAppear {
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
    
    
    
}

//#Preview {
//    PixivTextContentView()
//}
