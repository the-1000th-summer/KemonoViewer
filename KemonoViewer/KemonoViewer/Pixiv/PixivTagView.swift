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

struct PixivTagHoverTextModifier: ViewModifier {
    @State private var isHovering = false
    @State private var isLoadingDetail = false
    @State private var tagImageURL: URL? = nil
    
    let colorBefore: Color
    let colorAfter: Color
    let tagData: PixivTag
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(isHovering ? colorAfter : colorBefore)
            .onHover { hovering in
                if tagData.tagType == .xRestrict || tagData.tagType == .otherSpecial {
                    return
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .popover(isPresented: $isHovering) {
                ZStack(alignment: .bottom) {
                    if isLoadingDetail {
                        ProgressView()
                    } else {
                        ZStack(alignment: .bottom) {
                            KFImage(tagImageURL)
                                .placeholder { ProgressView() }
                                .cacheMemoryOnly(true)
                                .frame(width: 350, height: 275)
                            ZStack(alignment: .leading) {
                                Color(red: 29.0/255.0, green: 29.0/255.0, blue: 29.0/255.0)
                                    .frame(width: 350, height: 85)
                                Text(tagData.translation)
                                    .font(.system(size: 15))
                                    .fontWeight(.medium)
                                    .padding(.horizontal)
                                    .padding(.bottom, 15)
                            }
                        }
                    }
                }
                .onAppear {
                    Task {
                        await loadDetailData()
                    }
                }
                .frame(width: 350, height: 250)
            }
        
    }
    
    private func loadDetailData() async {
        await MainActor.run {
            isLoadingDetail = true
        }
        
        do {
            let url = URL(string: "https://www.pixiv.net/ajax/search/tags/\(tagData.name)")!
            var request = URLRequest(url: url)
            UtilFunc.configureBrowserHeaders(for: &request)
            
            let (fetcheddata, _) = try await URLSession.shared.data(for: request)
            let jsonObj = try JSON(data: fetcheddata)
            
            let imageURLStr = jsonObj["body"]["pixpedia"]["image"].stringValue.replacingOccurrences(of: "i.pximg.net", with: "i.pixiv.re")

            await MainActor.run {
                tagImageURL = URL(string: imageURLStr)!
                isLoadingDetail = false
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

// 扩展 View 使其更容易使用
extension View {
    func pixivTagHoverEffect(tagData: PixivTag) -> some View {
        let colorBefore: Color
        let colorAfter: Color
        
        switch tagData.tagType {
        case .xRestrict:
            colorBefore = .red
            colorAfter = .red
        case .otherSpecial:
            colorBefore = Color(red: 48.0/255.0, green: 106.0/255.0, blue: 140.0/255.0)
            colorAfter = Color(red: 48.0/255.0, green: 106.0/255.0, blue: 140.0/255.0)
        case .tag:
            colorBefore = Color(red: 48.0/255.0, green: 106.0/255.0, blue: 140.0/255.0)
            colorAfter = Color(red: 46.0/255.0, green: 144.0/255.0, blue: 250.0/255.0)
        case .translation:
            colorBefore = .gray
            colorAfter = .white
        }
        
        return self.modifier(PixivTagHoverTextModifier(
            colorBefore: colorBefore,
            colorAfter: colorAfter,
            tagData: tagData
        ))
    }
}

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

    
    var body: some View {
        HStack {
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
            await MainActor.run {
                tags = tagsData
                isLoadingData = false
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    PixivTagView(pixivContent: PixivContent_show(pixivPostId: "123897650", postName: "", comment: "", postDate: Date.now, likeCount: 0, bookmarkCount: 0, viewCount: 0, commentCount: 0, xRestrict: 2, isHowto: true, isOriginal: true, aiType: 2))
        .frame(width: 300, height: 300)

}
