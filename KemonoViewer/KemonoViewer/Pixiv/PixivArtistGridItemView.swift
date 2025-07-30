//
//  PixivArtistGridItemView.swift
//  KemonoViewer
//
//  Created on 2025/7/24.
//

import SwiftUI
import Kingfisher

struct PixivArtistGridItemView: View {
    let artistData: PixivArtist_show
    let size: CGSize
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .leading) {
                KFImage(
                    URL(filePath: Constants.pixivBaseDir)
                        .appendingPathComponent(artistData.folderName)
                        .appendingPathComponent(artistData.backgroundName)
                )
                .resizable()
                .overlay(
                    LinearGradient(colors: [
                        Color.black.opacity(0.5),
                        Color.black.opacity(0.8),
                    ], startPoint: .top, endPoint: .bottom)
                )
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                HStack {
                    KFImage(
                        URL(filePath: Constants.pixivBaseDir)
                            .appendingPathComponent(artistData.folderName)
                            .appendingPathComponent(artistData.avatarName)
                    )
                    .cacheMemoryOnly(true)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80.0, height: 80.0)
                    .clipShape(Circle())
                    .padding(.leading, 25)
                    .padding(.trailing, 10)
                    VStack(alignment: .leading) {
//                        Text(ServiceTitleColor(rawValue: artistData.service)?.title ?? "Unknown")
//                            .font(.system(size: 15))
//                            .fontWeight(.bold)
//                            .padding(4)
//                            .background(
//                                RoundedRectangle(cornerRadius: 5)
//                                    .fill(ServiceTitleColor(rawValue: artistData.service)?.color ?? .black)
//                            )
                        
                        Text(artistData.name)
                            .font(.system(size: 25))
                            .fontWeight(.light)
                    }
                }
            }
            Image(systemName: "circlebadge.fill")
                .padding(.top, 2)
                .padding(.trailing, 2)
                .foregroundStyle(.blue)
                .opacity(artistData.hasNotViewed ? 1 : 0)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
    }
    
    
}

//#Preview {
//    PixivArtistGridItemView()
//}
