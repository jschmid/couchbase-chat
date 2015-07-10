//
//  ChatViewController.swift
//  couchbase-chat
//
//  Created by Jonas Schmid on 10/07/15.
//  Copyright © 2015 schmid. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var liveQuery: CBLLiveQuery?

    var database: CBLDatabase = {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let db = app.database

        db.viewNamed("messages").setMapBlock("1") { (doc, emit) in
            if let type = doc["type"] as? String where type == "message" {
                if let room = doc["room"] as? String, let date = doc["created_at"] as? String {
                    emit([room, date], nil)
                }
            }
        }

        return db
        }()


    var chatroom: String? {
        didSet {
            self.configureView()
        }
    }

    func configureView() {
        if let chatroom = self.chatroom {
            self.title = chatroom
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let view = database.viewNamed("messages")
        let query = view.createQuery()
        let live = query.asLiveQuery()

        live.addObserver(self, forKeyPath: "rows", options: [], context: nil)

        liveQuery = live
    }

    deinit {
        liveQuery?.removeObserver(self, forKeyPath: "rows")
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        self.tableView.reloadData()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return liveQuery?.rows == nil ? 0 : 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if let rows = liveQuery?.rows {
            let count = rows.count
            return Int(count)
        }

        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        if let row = liveQuery?.rows?.rowAtIndex(UInt(indexPath.row)),
            let name = row.key as? String {
                cell.textLabel?.text = name
        }
        
        return cell
    }

//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cellIdentifier = "messageCell"
//
//        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell!
//
//        if cell == nil {
//            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: cellIdentifier)
//        }
//
//        if let cell = cell {
//            cell.textLabel!.text = "Yeah"
//            cell.detailTextLabel?.text = "ok"
//        }
//
//        return cell
//
//    }

}
