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
    @IBOutlet var notViewedFilterSwitch: NSSwitch!
    
    private var postsName = [String]()
    private var postsFolderName = [String]()
    private var postsId = [Int64]()
    private var postsViewed = [Bool]()
    private var artistName = ""
    private var artistId: Int64 = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataUpdate(_:)),
            name: .updatePostTableViewData,
            object: nil
        )
    }
    
    @IBAction func switchClicked(_ sender: NSSwitch) {
        artistSelected(artistName: self.artistName, artistId: self.artistId)
        if let splitVC = parent as? NSSplitViewController, let imageVC = splitVC.children[2] as? ImageViewController {
            imageVC.deselectPost()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return postsName.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let vw = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
        if postsViewed[row] {
            vw.imageView?.image = nil
        } else {
            vw.imageView?.image = NSImage(systemSymbolName: "circlebadge.fill", accessibilityDescription: nil)
        }
        
        vw.textField?.stringValue = postsName[row]
        
        return vw
    }
    
    func getPostsFolderName() -> [String] {
        return postsFolderName
    }
    func getPostsId() -> [Int64] {
        return postsId
    }
    
    func getSelectedPostIndex() -> Int {
        return postTableView.selectedRow
    }
    
    @objc func handleDataUpdate(_ notification: Notification) {
        print("update!")
        guard let viewedPostIndex = notification.userInfo?["viewedPostIndex"] as? Int else { return }
        postsViewed[viewedPostIndex] = true
        postTableView.reloadData(
            forRowIndexes: IndexSet(integer:viewedPostIndex),
            columnIndexes: IndexSet(integer: 0)
        )
        updateViewedPost(viewedPostIndex: viewedPostIndex)
    }
    
    func artistSelected(artistName: String, artistId: Int64) {
        self.artistName = artistName
        self.artistId = artistId
        postsName.removeAll()
        postsFolderName.removeAll()
        postsId.removeAll()
        postsViewed.removeAll()
        
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return
        }
        do {
            var query = KemonoPost.postTable.select(
                KemonoPost.e_postName,
                KemonoPost.e_postFolderName,
                KemonoPost.e_postId,
                KemonoPost.e_viewed
            ).filter(KemonoPost.e_artistIdRef == artistId)
            if notViewedFilterSwitch.state == .on {
                query = query.filter(KemonoPost.e_viewed == false)
            }
            for row in try db.prepare(query) {
                postsName.append(row[KemonoPost.e_postName])
                postsFolderName.append(row[KemonoPost.e_postFolderName])
                postsId.append(row[KemonoPost.e_postId])
                postsViewed.append(row[KemonoPost.e_viewed])
            }
        } catch {
            print(error.localizedDescription)
        }
        postTableView.reloadData()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = postTableView.selectedRow
        guard selectedRow != -1 else { return }
        
        updateViewedPost(viewedPostIndex: selectedRow)
        
        postsViewed[selectedRow] = true
        postTableView.reloadData(forRowIndexes: IndexSet(integer: selectedRow), columnIndexes: IndexSet(integer: 0))
        
        if let splitVC = parent as? NSSplitViewController, let imageVC = splitVC.children[2] as? ImageViewController {
            imageVC.postSelected(postId: postsId[selectedRow], postDirPath: URL(filePath: "/Volumes/ACG/kemono").appendingPathComponent(artistName).appendingPathComponent(postsFolderName[selectedRow]).path(percentEncoded: false))
        }
    }
    
    private func updateViewedPost(viewedPostIndex: Int) {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return
        }
        do {
            try db.run(KemonoPost.postTable.filter(KemonoPost.e_postId == postsId[viewedPostIndex]).update(KemonoPost.e_viewed <- true))
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
}
