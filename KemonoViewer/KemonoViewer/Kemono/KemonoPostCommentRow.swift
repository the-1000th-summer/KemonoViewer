//
//  PostCommentView.swift
//  KemonoViewer
//
//  Created on 2025/7/17.
//

import SwiftUI

struct KemonoPostCommentRow: View {
    let comment: KemonoComment
    
    let commentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            HStack {
                Text(comment.commenterName ?? "Anonymous")
                    .fontWeight(.bold)
                Text("·")
                    .foregroundStyle(.gray)
                Text((comment.publishedDatetime != nil) ? commentDateFormatter.string(from: comment.publishedDatetime!) : "Unknown datetime")
                    .foregroundStyle(.gray)
            }
            Text(comment.commentContent)
        }
        .font(.system(size: 15))
    }
}

#Preview {
    KemonoPostCommentRow(comment: KemonoComment(
        commenterName: "りゅーせい",
        commentContent: "見覚えのある場所だと思ったら、この前僕が巫女さんに挟んでもらった時の観覧射じゃないか!たまげたなあ",
        publishedDatetimeStr: "2024-05-07T12:36:51")
    )
}
