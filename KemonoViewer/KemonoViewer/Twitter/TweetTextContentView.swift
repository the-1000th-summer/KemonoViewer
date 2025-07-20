//
//  TweetTextContentView.swift
//  KemonoViewer
//
//  Created on 2025/7/20.
//

import SwiftUI

struct UnderlineOnHoverStyle: ButtonStyle {
    @State private var isHovering = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .underline(configuration.isPressed || isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

struct TweetContent_show {
    let tweetId: String
    let content: String
    let tweet_date: String
    let favorite_count: Int
    let retweet_count: Int
    let reply_count: Int
}

struct TweetTextContentView: View {
    
    @State private var isLoadingContent = false
    @State private var tweetContent: TweetContent_show? = nil
    
    @ObservedObject var imagePointer: TwitterImagePointer
    
    @State private var previousImageDate: String? = nil
    
    @ViewBuilder
    private func headerView() -> some View {
        
        HStack {
            Image(systemName: "person.circle")
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Link(imagePointer.getArtistName(), destination: URL(string: "https://x.com/\(imagePointer.getArtistTwitterId())")!)
                    .foregroundStyle(.foreground)
                    .font(.system(size: 15))
                    .fontWeight(.bold)
                    .padding(.bottom, -3)
                    .buttonStyle(UnderlineOnHoverStyle())
                
                Text("@" + imagePointer.getArtistTwitterId())
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }
        }

    }
    
    @ViewBuilder
    private func contentView() -> some View {
        if isLoadingContent {
            HStack{
                Spacer()
                ProgressView()
                Spacer()
            }
        } else {
            if let tweetContent {
                VStack(alignment: .leading) {
                    Link(destination: URL(string: "https://x.com/\(imagePointer.getArtistTwitterId())/status/\(tweetContent.tweetId)")!) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tweetContent.content)
                                    .font(.system(size: 15))
                                    .padding(.bottom, 1)
                                Text(tweetContent.tweet_date)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Divider()
                    HStack {
                        Image(systemName: "message")
                        Text(String(tweetContent.reply_count))
                        Spacer()
                        Image(systemName: "arrow.2.squarepath")
                        Text(String(tweetContent.retweet_count))
                        Spacer()
                        Image(systemName: "heart")
                        Text(String(tweetContent.favorite_count))
                    }
                }
            } else {
                Text("Content load failed.")
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                headerView()
                    .padding(.top, 10)
                    .padding(.bottom, 1)
                contentView()
                    .onAppear {
                        loadAllContentData()
                        previousImageDate = getCurrentImageDateFromURL(currentImageURL: imagePointer.currentImageURL)
                    }
                    .onChange(of: imagePointer.currentImageURL) {
                        if let currentImageURL = imagePointer.currentImageURL {
                            let currentImageDate = getCurrentImageDateFromURL(currentImageURL: currentImageURL)
                            if previousImageDate != currentImageDate {
                                loadAllContentData()
                                previousImageDate = currentImageDate
                            }
                        }
                    }
            }
            .padding(.horizontal)
        }
        
    }
    
    // 使用文件名中的日期判断是否是同一个post，存在漏洞
    // 可能有不同的post在相同的时间发出来（同日期同小时同分钟）
    private func getCurrentImageDateFromURL(currentImageURL: URL?) -> String? {
        guard let currentImageURL else { return nil }
        guard let firstSubStr = currentImageURL.lastPathComponent.split(separator: "_").first else { return nil}
        return String(firstSubStr)
    }
    
    private func loadAllContentData() {
        isLoadingContent = true
        Task.detached {
            let loadedData = await imagePointer.loadContent()
            await MainActor.run {
                tweetContent = loadedData
                isLoadingContent = false
            }
        }
    }
}

