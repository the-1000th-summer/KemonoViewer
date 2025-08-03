//
//  PixivTagView.swift
//  KemonoViewer
//
//  Created on 2025/8/2.
//

import SwiftUI
import Kingfisher
import WrappingHStack
import SwiftyJSON

enum PixivTagsType {
    case xRestrict
    case otherSpecial
    case tag
    case translation
}

struct PixivTag {
    let name: String
    let translation: String
    let tagType: PixivTagsType
    let tagLink: URL?
}

struct PixivTagView: View {
    let pixivContent: PixivContent_show
    
    @State private var isLoadingData = false
    
    @State private var specialTagCount = 0
    @State private var tags = [PixivTag]()
    @State private var errorMessage: String? = nil

    var body: some View {
        HStack {
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)
            } else {
                if isLoadingData {
                    ProgressView()
                } else {
                    WrappingHStack(tags.indices, id: \.self) { i in
                        let tag = tags[i]
                        HStack {
                            Link(
                                destination: tag.tagLink ?? URL(string: "https://www.pixiv.net/tags/\(tag.name)/artworks?ai_type=1")!
                            ) {
                                Text(tagShowText(tagData: tag))
                                    .font(.system(size: 15))
                                    .fontWeight((tag.tagType == .xRestrict || tag.tagType == .otherSpecial) ? .bold : .regular)
                            }
                            .pixivTagHoverEffect(tagData: tag)
                        }
                    }
                }
            }
            
        }
        .onAppear {
            isLoadingData = true
            Task {
                await loadTagData()
            }
        }
    }
    
    private func addSpectialTags() async -> [PixivTag] {
        var specialTagsData = [PixivTag]()
        
        if pixivContent.xRestrict == 1 {
            specialTagsData.append(PixivTag(name: "R-18", translation: "R-18", tagType: .xRestrict, tagLink: nil))
        } else if pixivContent.xRestrict == 2 {
            specialTagsData.append(PixivTag(name: "R-18G", translation: "R-18G", tagType: .xRestrict, tagLink: nil))
        }
        
        if pixivContent.aiType == 2 {
            specialTagsData.append(PixivTag(name: "AI生成", translation: "AI生成", tagType: .otherSpecial, tagLink: URL(string: "https://www.pixiv.help/hc/articles/11866167926809")))
        }
        if pixivContent.isOriginal {
            specialTagsData.append(PixivTag(name: "原创", translation: "原创", tagType: .otherSpecial, tagLink: URL(string: "https://www.pixiv.net/tags/オリジナル/artworks?ai_type=1")))
        }
        if pixivContent.isHowto {
            specialTagsData.append(PixivTag(name: "绘图方法", translation: "绘图方法", tagType: .otherSpecial, tagLink: URL(string: "https://www.pixiv.net/howto")))
        }
        return specialTagsData
    }
    
    private func tagShowText(tagData: PixivTag) -> String {
        if tagData.tagType == .tag {
            return "#\(tagData.name)"
        } else if tagData.tagType == .translation {
            return tagData.translation
        } else {
            return tagData.name
        }
    }

    private func loadTagData() async {
        var tagsData = await addSpectialTags()
        do {
            let url = URL(string: "https://www.pixiv.net/ajax/illust/\(pixivContent.pixivPostId)")!
            var request = URLRequest(url: url)
            UtilFunc.configureBrowserHeaders(for: &request)
            
            let (fetcheddata, _) = try await URLSession.shared.data(for: request)
            let jsonObj = try JSON(data: fetcheddata)
            
            for tagObj in jsonObj["body"]["tags"]["tags"] {
                
                if tagObj.1["translation"].exists() {
                    tagsData.append(
                        PixivTag(
                            name: tagObj.1["tag"].stringValue,
                            translation: tagObj.1["translation"]["en"].stringValue,
                            tagType: .tag,
                            tagLink: nil
                        )
                    )
                    tagsData.append(
                        PixivTag(
                            name: tagObj.1["tag"].stringValue,
                            translation: tagObj.1["translation"]["en"].stringValue,
                            tagType: .translation,
                            tagLink: nil
                        )
                    )
                } else {
                    tagsData.append(
                        PixivTag(
                            name: tagObj.1["tag"].stringValue,
                            translation: tagObj.1["tag"].stringValue,
                            tagType: .tag,
                            tagLink: nil
                        )
                    )
                }
            }
            
            let likeCount = jsonObj["body"]["likeCount"]
            let bookmarkCount = jsonObj["body"]["bookmarkCount"]
            let viewCount = jsonObj["body"]["viewCount"]
            let commentCount = jsonObj["body"]["commentCount"]

            await MainActor.run {
                tags = tagsData
                
                if likeCount.exists() && bookmarkCount.exists() && viewCount.exists() && commentCount.exists() {
                    NotificationCenter.default.post(
                        name: .pixivInteractionUpdated,
                        object: nil,
                        userInfo: [
                            "likeCount": likeCount.intValue,
                            "bookmarkCount": bookmarkCount.intValue,
                            "viewCount": viewCount.intValue,
                            "commentCount": commentCount.intValue
                        ]
                    )
                }
                isLoadingData = false
            }
        } catch {
            print(error.localizedDescription)
            await MainActor.run {
                errorMessage = "Tag加载失败：\(error.localizedDescription)"
                isLoadingData = false
            }
        }
    }
}

#Preview {
    PixivTagView(pixivContent: PixivContent_show(pixivPostId: "123897650", postName: "", comment: "", postDate: Date.now, likeCount: 0, bookmarkCount: 0, viewCount: 0, commentCount: 0, xRestrict: 2, isHowto: true, isOriginal: true, aiType: 2))
        .frame(width: 300, height: 300)

}
