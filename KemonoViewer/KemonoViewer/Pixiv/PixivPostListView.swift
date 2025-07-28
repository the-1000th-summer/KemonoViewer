//
//  PixivPostListView.swift
//  KemonoViewer
//
//  Created on 2025/7/24.
//

import SwiftUI

struct PixivPost_show: Hashable, Codable {
    let name: String
    let folderName: String
    let id: Int64
    let imageNumber: Int
    let postDate: Date
    let viewed: Bool
}

struct PixivPostListView: View {
    @Binding var postsData: [PixivPost_show]
    @Binding var postSelectedIndex: Int?
    
    var body: some View {
        List(postsData.indices, id: \.self, selection: $postSelectedIndex) { postCurrentIndex in
            HStack {
                Image(systemName: "circlebadge.fill")
                    .foregroundStyle(.blue)
                    .opacity(postsData[postCurrentIndex].viewed ? 0 : 1)
                Text(postsData[postCurrentIndex].name)
            }
        }
    }
}

//#Preview {
//    PixivPostListView()
//}
