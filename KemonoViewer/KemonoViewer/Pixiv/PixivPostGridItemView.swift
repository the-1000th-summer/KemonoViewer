//
//  PixivPostGridItemView.swift
//  KemonoViewer
//
//  Created on 2025/7/29.
//

import SwiftUI

struct PixivImageNumberView: View {
    let imageNumber: Int
    
    var body: some View {
        if imageNumber > 1 {
            HStack {
                Image(systemName: "square.fill.on.square.fill")
                    .font(.system(size: 11))
                Text("\(imageNumber)")
                    .font(.system(size: 13))
                    .padding(.leading, -7)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 7)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
            )
        }
    }
}

struct XRestrictView: View {
    let xRestrict: Int
    
    var body: some View {
        if let xRestrictStr = getXRestrictStr(xRestrict: xRestrict) {
            Text(xRestrictStr)
                .font(.system(size: 12))
                .fontWeight(.semibold)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(red: 255.0/255.0, green: 55.0/255.0, blue: 89.0/255.0))
                )
        }
    }
    
    private func getXRestrictStr(xRestrict: Int) -> String? {
        if xRestrict == 1 {
            return "R-18"
        }
        if xRestrict == 2 {
            return "R-18G"
        }
        return nil
    }
}

struct PixivPostGridItemView: View {
    let postData: PixivPost_show
    let size: Double
    let initialSize: Double
    let imageURL: URL?
    let isSelected: Bool
    
    var body: some View {
        
        ZStack(alignment: .topTrailing) {
            GridItemMediaView(initialSize: initialSize, imageURL: imageURL)
                .frame(width: size, height: size)
            VStack {
                HStack(alignment: .top) {
                    XRestrictView(xRestrict: postData.xRestrict)
                    Spacer()
                    PixivImageNumberView(imageNumber: postData.imageNumber)
                }
                .padding(5)
                Spacer()
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

        
        
    }
    
    
}

#Preview {
    PixivPostGridItemView(
        postData: PixivPost_show(
            name: "そう...その調子だよ...",
            folderName: "[2014-01-21]そう...その調子だよ",
            coverName: "41105311_p0.jpg",
            id: 1,
            imageNumber: 2,
            postDate: Date.now,
            xRestrict: 1,
            viewed: false
        ),
        size: 222.666,
        initialSize: 227.666,
        imageURL: URL(filePath: "/Volumes/ACG/pixiv/あぐに (9645735)/[2014-01-21]そう...その調子だよ/41105311_p0.jpg"),
        isSelected: false
    )
    .frame(width: 226, height: 236)
}
