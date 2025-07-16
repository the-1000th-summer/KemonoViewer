//
//  ArtistGridItemView.swift
//  KemonoViewer
//
//  Created on 2025/7/16.
//

import SwiftUI
import Kingfisher

enum ServiceTitleColor: String {
    case fanbox, patreon, fantia, discord, gumroad, dlsite, boosty, subscribestar
    
    var title: String {
        switch self {
        case .fanbox:
            return "Pixiv Fanbox"
        case .patreon:
            return "Patreon"
        case .fantia:
            return "Fantia"
        case .discord:
            return "Discord"
        case .gumroad:
            return "Gumroad"
        case .dlsite:
            return "DLsite"
        case .boosty:
            return "Boosty"
        case .subscribestar:
            return "SubscribeStar"
        }
    }
    
    var color: Color {
        switch self {
        case .fanbox:
            return Color(red: 44.0/255.0, green: 51.0/255.0, blue: 60.0/255.0)
        case .patreon:
            return Color(red: 250.0/255.0, green: 87.0/255.0, blue: 66.0/255.0)
        case .fantia:
            return Color(red: 255.0/255.0, green: 9.0/255.0, blue: 127.0/255.0)
        case .discord:
            return Color(red: 81.0/255.0, green: 101.0/255.0, blue: 246.0/255.0)
        case .gumroad:
            return Color(red: 43.0/255.0, green: 159.0/255.0, blue: 164.0/255.0)
        case .dlsite:
            return Color(red: 5.0/255.0, green: 42.0/255.0, blue: 131.0/255.0)
        case .boosty:
            return Color(red: 253.0/255.0, green: 96.0/255.0, blue: 53.0/255.0)
        case .subscribestar:
            return Color(red: 0.0/255.0, green: 150.0/255.0, blue: 136.0/255.0)
        }
    }
}

struct ArtistGridItemView: View {
    let artistData: Artist_show
    let size: CGSize
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .leading) {
                
                KFImage(URL(string: "https://img.kemono.su/banners/\(artistData.service)/\(artistData.kemonoId)"))
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
                    KFImage(URL(string: "https://img.kemono.su/icons/\(artistData.service)/\(artistData.kemonoId)"))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80.0, height: 80.0)
                        .cornerRadius(10.0)
                        .padding(.leading, 25)
                        .padding(.trailing, 10)
                    VStack(alignment: .leading) {
                        Text(ServiceTitleColor(rawValue: artistData.service)?.title ?? "Unknown")
                            .font(.system(size: 15))
                            .fontWeight(.bold)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(ServiceTitleColor(rawValue: artistData.service)?.color ?? .black)
                            )
                        
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
                .opacity(artistData.hasNotviewed ? 1 : 0)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
    }
}

#Preview {
    ArtistGridItemView(
        artistData: Artist_show(
            name: "Belko",
            service: "fanbox",
            kemonoId: "39123643",
            hasNotviewed: false,
            id: 1
        ),
        size: CGSize(width: 480, height: 130),
        isSelected: false
    )
}
