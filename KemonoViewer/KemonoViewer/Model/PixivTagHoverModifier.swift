//
//  PixivTagHoverModifier.swift
//  KemonoViewer
//
//  Created on 2025/8/3.
//

import SwiftUI
import Kingfisher
import SwiftyJSON

struct PixivTagHoverModifier: ViewModifier {
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
                            .frame(width: 350, height: 250)
                    } else {
                        ZStack(alignment: .bottom) {
                            if let tagImageURL {
                                KFImage(tagImageURL)
                                    .placeholder { ProgressView() }
                                    .onFailureView {
                                        VStack {
                                            Image(systemName: "exclamationmark.triangle")
                                            Text("Image load failed.")
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                    .cacheMemoryOnly(true)
                                    .frame(width: 350, height: 275)
                            }
                            ZStack(alignment: .leading) {
                                Color(red: 29.0/255.0, green: 29.0/255.0, blue: 29.0/255.0)
                                    .frame(width: 350, height: 85)
                                Text(tagData.translation)
                                    .font(.system(size: 15))
                                    .fontWeight(.medium)
                                    .padding(.horizontal)
                                    .padding(.bottom, tagImageURL == nil ? 0 : 15)
                            }
                        }
                        .frame(width: 350, height: tagImageURL == nil ? 85 : 250)
                    }
                }
                .onAppear {
                    Task {
                        await loadDetailData()
                    }
                }
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
            
            // jsonObj["body"]["pixpedia"]["image"] my not exist: imageURLStr will be empty.
            let imageURLStr = jsonObj["body"]["pixpedia"]["image"].stringValue.replacingOccurrences(of: "i.pximg.net", with: "i.pixiv.re")

            await MainActor.run {
                tagImageURL = URL(string: imageURLStr)
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
        
        return self.modifier(PixivTagHoverModifier(
            colorBefore: colorBefore,
            colorAfter: colorAfter,
            tagData: tagData
        ))
    }
}
