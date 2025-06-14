//
//  ArtistTableViewController.swift
//  KemonoViewer
//
//  Created on 2025/6/13.
//

import Cocoa
import SQLite

class ArtistTableViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet var artistTableView: NSTableView!
    
    var artistsName = [String]()
    var artistsId = [Int64]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        loadData()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return artistsName.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let vw = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
        vw.textField?.stringValue = artistsName[row]
        return vw
    }
    
    private func loadData() {
        guard let db = DatabaseManager.shared.getConnection() else {
            print("数据库初始化失败")
            return
        }
        do {
            for row in try db.prepare(Artist.artistTable.select(Artist.e_artistName, Artist.e_artistId)) {
                artistsName.append(row[Artist.e_artistName])
                artistsId.append(row[Artist.e_artistId])
            }
//            artistsName = try db.prepare(Artist.artistTable.select(Artist.e_artistName)).map { row in
//                return row[Artist.e_artistName] // 返回 String? 类型
//            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard artistTableView.selectedRow != -1 else { return }
        guard let splitVC = parent as? NSSplitViewController else {
            return
        }
        if let postTVC = splitVC.children[1] as? PostTableViewController {
            postTVC.artistSelected(artistName: artistsName[artistTableView.selectedRow], artistId: artistsId[artistTableView.selectedRow])
        }
    }
    
}
