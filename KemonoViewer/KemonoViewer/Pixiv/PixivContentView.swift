//
//  PixivContentView.swift
//  KemonoViewer
//
//  Created on 2025/7/18.
//

import SwiftUI
import Kingfisher

struct PixivContentView: View {
    init() {
        KingfisherManager.shared.cache.clearCache(completion: nil)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 3)]) {
                ForEach(1..<352) { index in
                    VStack {
                        KFImage(URL(string: "https://github.com/tatsuz0u/Imageset/blob/main/JPGs/\(index).jpg?raw=true"))
                            .placeholder {
                                Color(.gray)
                            }
                            .resizable().scaledToFit()
                        Text("\(index)").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    PixivContentView()
}
