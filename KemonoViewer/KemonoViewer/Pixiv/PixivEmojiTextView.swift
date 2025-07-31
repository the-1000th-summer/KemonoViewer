//
//  PixivEmojiTextView.swift
//  KemonoViewer
//
//  Created on 2025/7/31.
//

import SwiftUI

enum TextSegment: Identifiable {
    case text(String)
    case emoji(String)
    
    var id: String {
        switch self {
        case .text(let value): return "text-\(value)"
        case .emoji(let name): return "emoji-\(name)"
        }
    }
}

struct PixivEmojiTextView: View {
    let segments: [TextSegment]
    
    init(content: String) {
        self.segments = Self.parse(content, validEmojiNames: Constants.pixivValidEmojiNames)
    }
    
    var body: some View {
        segments.reduce(Text("")) { (result, segment) in
            switch segment {
            case .text(let value):
                return result + Text(value)
            case .emoji(let name):
                return result + Text(Image(name))
            }
        }
    }
    
    private static func parse(_ string: String, validEmojiNames: Set<String>) -> [TextSegment] {
        let pattern = "\\(([^)]+)\\)"
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = string as NSString
            let range = NSRange(location: 0, length: nsString.length)
            var segments = [TextSegment]()
            var lastIndex = 0
            
            regex.enumerateMatches(in: string, range: range) { match, _, _ in
                guard let match = match else { return }
                
                // 添加匹配前的普通文本
                let matchRange = match.range
                if lastIndex < matchRange.location {
                    let textRange = NSRange(location: lastIndex, length: matchRange.location - lastIndex)
                    let text = nsString.substring(with: textRange)
                    segments.append(.text(text))
                }
                
                // 提取括号内的内容
                let emojiName = nsString.substring(with: match.range(at: 1))
                
                // 检查是否在有效集合中
                if validEmojiNames.contains(emojiName) {
                    segments.append(.emoji(emojiName))
                } else {
                    // 不在集合中，保留完整括号内容作为文本
                    let fullMatch = nsString.substring(with: matchRange)
                    segments.append(.text(fullMatch))
                }
                
                lastIndex = matchRange.location + matchRange.length
            }
            
            // 添加剩余文本
            if lastIndex < nsString.length {
                let text = nsString.substring(from: lastIndex)
                segments.append(.text(text))
            }
            
            return segments
        } catch {
            return [.text(string)]
        }
    }
}

//#Preview {
//    PixivEmojiTextView()
//}
