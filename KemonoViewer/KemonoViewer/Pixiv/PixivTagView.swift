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
    let tag: String
    let tagTranslation: String
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(isHovering ? colorAfter : colorBefore)
            .onHover { hovering in
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
                                Text(tagTranslation)
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
            let url = URL(string: "https://www.pixiv.net/ajax/search/tags/\(tag)")!
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
    func pixivTagHoverEffect(_ colorBefore: Color, _ colorAfter: Color, tag: String, tagTranslation: String) -> some View {
        self.modifier(PixivTagHoverTextModifier(
            colorBefore: colorBefore,
            colorAfter: colorAfter,
            tag: tag,
            tagTranslation: tagTranslation
        ))
    }
}

struct PixivTagView: View {
    let pixivContent: PixivContent_show
    
    @State private var isLoadingData = false

    @State private var tags = [String]()
    @State private var tagsTranslation = [String?]()
    
    var body: some View {
        VStack {
            if isLoadingData {
                ProgressView()
            } else {
                WrappingHStack(tags.indices, id: \.self) { i in
                    let tag = tags[i]
                    let tagTranslation = tagsTranslation[i]
                    HStack {
                        Link(destination: URL(string: "https://www.pixiv.net/tags/\(tag)/artworks?ai_type=1")!) {
                            Text("#\(tag)")
                                .font(.system(size: 15))
                        }
                        .pixivTagHoverEffect(
                            Color(red: 48.0/255.0, green: 106.0/255.0, blue: 140.0/255.0),
                            Color(red: 46.0/255.0, green: 144.0/255.0, blue: 250.0/255.0),
                            tag: tag, tagTranslation: tagTranslation ?? tag
                        )
                        
                        if let tagTranslation {
                            Link(destination: URL(string: "https://www.pixiv.net/tags/\(tag)/artworks?ai_type=1")!) {
                                Text("\(tagTranslation)")
                                    .font(.system(size: 15))
                            }
                            .pixivTagHoverEffect(.gray, .white, tag: tag, tagTranslation: tagTranslation)
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

    private func loadTagData() async {
        do {
            let url = URL(string: "https://www.pixiv.net/ajax/illust/\(pixivContent.pixivPostId)")!
            var request = URLRequest(url: url)
            UtilFunc.configureBrowserHeaders(for: &request)
            
            let (fetcheddata, _) = try await URLSession.shared.data(for: request)
            let jsonObj = try JSON(data: fetcheddata)
            
            let tagsData = jsonObj["body"]["tags"]["tags"].map { $0.1["tag"].stringValue }
            let tagsTranslationData: [String?] = jsonObj["body"]["tags"]["tags"].map {
                if $0.1["translation"].exists() {
                    return $0.1["translation"]["en"].stringValue
                } else {
                    return nil
                }
            }
            await MainActor.run {
                tags = tagsData
                tagsTranslation = tagsTranslationData
                isLoadingData = false
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    PixivTagView(pixivContent: PixivContent_show(pixivPostId: "123897650", postName: "", comment: "", postDate: Date.now, likeCount: 0, bookmarkCount: 0, viewCount: 0, commentCount: 0, xRestrict: 0, isHowto: false, isOriginal: false, aiType: 0))
        .frame(width: 300, height: 300)

}
