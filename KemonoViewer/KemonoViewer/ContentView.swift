//
//  ContentView.swift
//  KemonoViewer
//
//  Created on 2025/6/29.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.appearsActive) private var windowIsActive
    
    @State private var showErrorView = false
    @State private var errorMessage = ""
    
    var body: some View {
        HStack {
            
            Button(action: {
                let baseDirValid = checkUserDefaultValid(userDefaultKey: AppStorageKeys.kemonoBaseDir)
                let dbPathValid = checkUserDefaultValid(userDefaultKey: AppStorageKeys.kemonoDatabaseFilePath)
                if baseDirValid && dbPathValid {
                    openWindow(id: "kemonoViewer")
                }
            }) {
                VStack {
                    Image("kemonoIcon_round")
                        .resizable()
                        .frame(width: 200, height: 200)
                    Text("Kemono")
                        .font(.system(size: 20))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                let baseDirValid = checkUserDefaultValid(userDefaultKey: AppStorageKeys.twitterBaseDir)
                let dbPathValid = checkUserDefaultValid(userDefaultKey: AppStorageKeys.twitterDatabaseFilePath)
                if baseDirValid && dbPathValid {
                    openWindow(id: "twitterViewer")
                }
            }) {
                VStack {
                    Image("twitterIcon_round")
                        .resizable()
                        .frame(width: 200, height: 200)
                    Text("Twitter")
                        .font(.system(size: 20))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                let baseDirValid = checkUserDefaultValid(userDefaultKey: AppStorageKeys.pixivBaseDir)
                let dbPathValid = checkUserDefaultValid(userDefaultKey: AppStorageKeys.pixivDatabaseFilePath)
                if baseDirValid && dbPathValid {
                    openWindow(id: "pixivViewer")
                }
            }) {
                VStack {
                    Image("pixivIcon_round")
                        .resizable()
                        .frame(width: 200, height: 200)
                    Text("Pixiv")
                        .font(.system(size: 20))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
//            Button("Kemono Renamer") {
//                openWindow(id: "renamer")
//            }
        }
        .padding()
        .alert("Error", isPresented: $showErrorView) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: windowIsActive) { wasActive, isNowActive in
            if isNowActive {
                NSApp.applicationIconImage = nil
            }
        }
    }
    
    private func checkUserDefaultValid(userDefaultKey: String) -> Bool {
        let path = UserDefaults.standard.string(forKey: userDefaultKey)
        
        guard let path, !path.isEmpty else {
            showErrorView = true
            errorMessage = "Please set \(AppStorageKeys.keyMapDesc[userDefaultKey]!) in Settings first."
            return false
        }
        var pathIsDirectory: ObjCBool = false
        let pathExists = FileManager.default.fileExists(atPath: path, isDirectory: &pathIsDirectory)
        if !pathExists {
            showErrorView = true
            errorMessage = "Path: \(path) not exists in the filesystem."
            return false
        }
        let shouldBeDir = AppStorageKeys.keyMapIsDir[userDefaultKey]!
        if shouldBeDir != pathIsDirectory.boolValue {
            showErrorView = true
            errorMessage = "Path: \(path) should point to a \(shouldBeDir ? "directory" : "file")."
            return false
        }
        
        if shouldBeDir {
            return true
        } else {
            let validSQLiteFile = UtilFunc.checkIfIsValidSQLiteFile(inputPath: path)
            if !validSQLiteFile {
                showErrorView = true
                errorMessage = "Path: \(path) is not a valid SQLite file."
                return false
            }
        }
        return true
    }
    
}

//#Preview {
//    ContentView()
//}
