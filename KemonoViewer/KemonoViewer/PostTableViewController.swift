//
//  PostTableViewController.swift
//  KemonoViewer
//
//  Created on 2025/6/13.
//

import Cocoa
import SQLite

class PostTableViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet var postTableView: NSTableView!
    
    private var postsName = [String]()
    private var postsFolderName = [String]()
    private var postsId = [Int64]()
    private var artistName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return postsName.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let vw = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
        vw.textField?.stringValue = postsName[row]
        
        return vw
    }
    
    func artistSelected(artistName: String, artistId: Int64) {
        self.artistName = artistName
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return
        }
        do {
            let query = KemonoPost.postTable.select(KemonoPost.e_postName, KemonoPost.e_postFolderName, KemonoPost.e_postId).filter(KemonoPost.e_artistIdRef == artistId)
            for row in try db.prepare(query) {
                postsName.append(row[KemonoPost.e_postName])
                postsFolderName.append(row[KemonoPost.e_postFolderName])
                postsId.append(row[KemonoPost.e_postId])
            }
            
        } catch {
            print(error.localizedDescription)
        }
        postTableView.reloadData()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard postTableView.selectedRow != -1 else { return }
        guard let splitVC = parent as? NSSplitViewController else {
            return
        }
        if let imageVC = splitVC.children[2] as? ImageViewController {
            imageVC.postSelected(postId: postsId[postTableView.selectedRow], postDirPath: URL(filePath: "/Volumes/ACG/kemono").appendingPathComponent(artistName).appendingPathComponent(postsFolderName[postTableView.selectedRow]).path(percentEncoded: false))
        }
    }
    
}
