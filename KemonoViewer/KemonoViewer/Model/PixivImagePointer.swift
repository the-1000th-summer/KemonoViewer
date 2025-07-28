//
//  PixivImagePointer.swift
//  KemonoViewer
//
//  Created on 2025/7/26.
//

import Foundation

struct PixivImagePointerData: Hashable, Codable {
    var id = UUID()
    
    let artistsData: [PixivArtist_show]
    let postsData: [PixivPost_show]
    let currentPostImagesName: [String]
    
    let currentArtistIndex: Int
    let currentPostIndex: Int
    let currentImageIndex: Int
}

final class PixivImagePointer: ObservableObject {
    private var artistsData = [PixivArtist_show]()
    private var postsData = [PixivPost_show]()
    private var currentPostImagesName = [String]()
    
    private var currentArtistIndex = 0
    private var currentPostIndex = 0
    private var currentImageIndex = 0
    
    @Published var currentPostDirURL: URL?
    @Published var currentImageURL: URL?
    
    func loadData(imagePointerData: PixivImagePointerData) {
        self.artistsData = imagePointerData.artistsData
        self.postsData = imagePointerData.postsData
        self.currentPostImagesName = imagePointerData.currentPostImagesName
        self.currentArtistIndex = imagePointerData.currentArtistIndex
        self.currentPostIndex = imagePointerData.currentPostIndex
        self.currentImageIndex = imagePointerData.currentImageIndex
        
        currentPostDirURL = getCurrentPostDirURL()
        currentImageURL = getCurrentImageURL()
        
        
    }
    
    private func getCurrentPostDirURL() -> URL? {
        if postsData.isEmpty { return nil }
        return URL(filePath: Constants.pixivBaseDir)
            .appendingPathComponent(artistsData[currentArtistIndex].folderName)
            .appendingPathComponent(postsData[currentPostIndex].folderName)
    }
    
    private func getCurrentImageURL() -> URL? {
        if let cpdu = getCurrentPostDirURL() {
            return cpdu.appendingPathComponent(
                currentPostImagesName[currentImageIndex]
            )
        }
        return nil
    }
    
    
}
