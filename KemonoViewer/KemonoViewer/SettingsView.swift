//
//  SettingsView.swift
//  KemonoViewer
//
//  Created on 2025/8/1.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let sqliteFile = UTType(filenameExtension: "sqlite")!
    static let sqlite3File = UTType(filenameExtension: "sqlite3")!
}

enum BaseDirPathType: String, CaseIterable {
    case kemonoBaseDir = "Kemono base directory"
    case twitterBaseDir = "Twitter base directory"
    case pixivBaseDir = "Pixiv base directory"
}
enum DatabasePathType: String, CaseIterable {
    case kemonoDatabaseFilePath = "Kemono database location"
    case twitterDatabaseFilePath = "Twitter database location"
    case pixivDatabaseFilePath = "Pixiv database location"
}

class AppStorageKeys {
    static let kemonoBaseDir = "kemonoBaseDir"
    static let twitterBaseDir = "twitterBaseDir"
    static let pixivBaseDir = "pixivBaseDir"
    static let kemonoDatabaseFilePath = "kemonoDatabaseFilePath"
    static let twitterDatabaseFilePath = "twitterDatabaseFilePath"
    static let pixivDatabaseFilePath = "pixivDatabaseFilePath"
    
    static let keyMapDesc: [String: String] = [
        kemonoBaseDir: BaseDirPathType.kemonoBaseDir.rawValue,
        twitterBaseDir: BaseDirPathType.twitterBaseDir.rawValue,
        pixivBaseDir: BaseDirPathType.pixivBaseDir.rawValue,
        kemonoDatabaseFilePath: DatabasePathType.kemonoDatabaseFilePath.rawValue,
        twitterDatabaseFilePath: DatabasePathType.twitterDatabaseFilePath.rawValue,
        pixivDatabaseFilePath: DatabasePathType.pixivDatabaseFilePath.rawValue
    ]
    
    static let keyMapIsDir: [String: Bool] = [
        kemonoBaseDir: true,
        twitterBaseDir: true,
        pixivBaseDir: true,
        kemonoDatabaseFilePath: false,
        twitterDatabaseFilePath: false,
        pixivDatabaseFilePath: false
    ]
}

class DBShouldReload {
    static var kemonoReload = false
    static var twitterReload = false
    static var pixivReload = false
}

struct SettingsView: View {
    @AppStorage(AppStorageKeys.kemonoBaseDir) private var kemonoBaseDir = ""
    @AppStorage(AppStorageKeys.twitterBaseDir) private var twitterBaseDir = ""
    @AppStorage(AppStorageKeys.pixivBaseDir) private var pixivBaseDir = ""
    
    @AppStorage(AppStorageKeys.kemonoDatabaseFilePath) private var kemonoDatabaseFilePath = ""
    @AppStorage(AppStorageKeys.twitterDatabaseFilePath) private var twitterDatabaseFilePath = ""
    @AppStorage(AppStorageKeys.pixivDatabaseFilePath) private var pixivDatabaseFilePath = ""
    
    @State private var showDirPicker = false
    @State private var showDatabasePicker = false
    
    @State private var activeBaseDirPathType: BaseDirPathType?
    @State private var activeDatabasePathType: DatabasePathType?
    
    @State private var showErrorView = false
    @State private var errorMessage = ""
    
    @StateObject private var windowState = WindowOpenStatusManager.shared
    
    private var baseDirPathBindings: [BaseDirPathType: Binding<String>] {
        [
            .kemonoBaseDir: $kemonoBaseDir,
            .twitterBaseDir: $twitterBaseDir,
            .pixivBaseDir: $pixivBaseDir,
        ]
    }
    private var databasePathBindings: [DatabasePathType: Binding<String>] {
        [
            .kemonoDatabaseFilePath: $kemonoDatabaseFilePath,
            .twitterDatabaseFilePath: $twitterDatabaseFilePath,
            .pixivDatabaseFilePath: $pixivDatabaseFilePath
        ]
    }
    
    var body: some View {
        Form {
            Group {
                HStack {
                    TextField(BaseDirPathType.kemonoBaseDir.rawValue, text: $kemonoBaseDir)
                    Button("Browse...") {
                        showDirPicker = true
                        activeBaseDirPathType = .kemonoBaseDir
                    }
                }
                .disabled(windowState.shouldDisableKemonoControl)
                HStack {
                    TextField(BaseDirPathType.twitterBaseDir.rawValue, text: $twitterBaseDir)
                    Button("Browse...") {
                        showDirPicker = true
                        activeBaseDirPathType = .twitterBaseDir
                    }
                }
                .disabled(windowState.shouldDisableTwitterControl)
                HStack {
                    TextField(BaseDirPathType.pixivBaseDir.rawValue, text: $pixivBaseDir)
                    Button("Browse...") {
                        showDirPicker = true
                        activeBaseDirPathType = .pixivBaseDir
                    }
                }
                .disabled(windowState.shouldDisablePixivControl)
            }
            .fileImporter(isPresented: $showDirPicker, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
                    handleFolderSelection(result: result)
            }
            
            Group {
                HStack {
                    TextField(DatabasePathType.kemonoDatabaseFilePath.rawValue, text: $kemonoDatabaseFilePath)
                    Button("Browse...") {
                        showDatabasePicker = true
                        activeDatabasePathType = .kemonoDatabaseFilePath
                    }
                }
                .disabled(windowState.shouldDisableKemonoControl)
                HStack {
                    TextField(DatabasePathType.twitterDatabaseFilePath.rawValue, text: $twitterDatabaseFilePath)
                    Button("Browse...") {
                        showDatabasePicker = true
                        activeDatabasePathType = .twitterDatabaseFilePath
                    }
                }
                .disabled(windowState.shouldDisableTwitterControl)
                HStack {
                    TextField(DatabasePathType.pixivDatabaseFilePath.rawValue, text: $pixivDatabaseFilePath)
                    Button("Browse...") {
                        showDatabasePicker = true
                        activeDatabasePathType = .pixivDatabaseFilePath
                    }
                }
                .disabled(windowState.shouldDisablePixivControl)
            }
            .fileImporter(isPresented: $showDatabasePicker, allowedContentTypes: [.sqliteFile, .sqlite3File], allowsMultipleSelection: false) { result in
                    handleDatabaseSelection(result: result)
            }
        }
        .padding()
        .frame(width: 600)
        .alert("Error", isPresented: $showErrorView) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: kemonoBaseDir) {
            DBShouldReload.kemonoReload = true
        }
        .onChange(of: kemonoDatabaseFilePath) {
            DBShouldReload.kemonoReload = true
        }
    }
    
    
    private func handleFolderSelection(result: Result<[URL], Error>) {
        defer { activeBaseDirPathType = nil }
        
        guard let pathType = activeBaseDirPathType, let binding = baseDirPathBindings[pathType] else {
            return
        }
        
        switch result {
        case .success(let urls):
            if let url = urls.first {
                binding.wrappedValue = url.path(percentEncoded: false)
            }
        case .failure(let error):
            errorMessage = "路径选择失败: \(error.localizedDescription)"
            showErrorView = true
        }
    }
    
    private func handleDatabaseSelection(result: Result<[URL], Error>) {
        defer { activeDatabasePathType = nil }
        
        guard let pathType = activeDatabasePathType, let binding = databasePathBindings[pathType] else {
            return
        }
        
        switch result {
        case .success(let urls):
            if let url = urls.first {
                binding.wrappedValue = url.path(percentEncoded: false)
            }
        case .failure(let error):
            errorMessage = "路径选择失败: \(error.localizedDescription)"
            showErrorView = true
        }
    }
    
}

#Preview {
    SettingsView()
}
