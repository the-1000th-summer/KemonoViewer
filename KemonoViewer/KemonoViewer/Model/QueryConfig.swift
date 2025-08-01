//
//  QueryConfig.swift
//  KemonoViewer
//
//  Created on 2025/7/21.
//

import Foundation

enum SortOrder: String, CaseIterable, Codable {
    case ascending = "arrowtriangle.up.fill"
    case descending = "arrowtriangle.down.fill"
}

protocol QueryConfig: Equatable, Codable, Hashable {
    associatedtype SortKey: RawRepresentable, CaseIterable, Codable, Hashable
        where SortKey.RawValue == String, SortKey.AllCases: RandomAccessCollection
    
    var sortKey: SortKey { get set }
    var sortOrder: SortOrder { get set }
    var onlyShowNotViewedPost: Bool { get set }
}

struct KemonoPostQueryConfig: QueryConfig {
    enum SortKey: String, CaseIterable, Codable {
        case date = "Post date"
        case postTitle = "Name"
        case attachmentNumber = "Attachment number"
    }
    
    var sortKey: SortKey = .date
    var sortOrder: SortOrder = .ascending
    var onlyShowNotViewedPost = false
}

// 新配置（扩展了排序键）
struct TwitterImageQueryConfig: QueryConfig {
    enum SortKey: String, CaseIterable, Codable {
        case date = "Tweet date"
        case tweetContent = "Tweet content"
        case favoriteCount = "Favorite count"
        case retweetCount = "Retweet count"
        case replyCount = "Reply count"
    }
    
    var sortKey: SortKey = .date
    var sortOrder: SortOrder = .ascending
    var onlyShowNotViewedPost = false
}

struct PixivPostQueryConfig: QueryConfig {
    enum SortKey: String, CaseIterable, Codable {
        case date = "Post date"
        case postTitle = "Name"
        case likeCount = "Like count"
        case bookmarkCount = "Bookmark count"
        case viewCount = "View count"
        case commentCount = "Comment count"
        case imageNumber = "Image number"
    }
    
    var sortKey: SortKey = .date
    var sortOrder: SortOrder = .ascending
    var onlyShowNotViewedPost = false
}
