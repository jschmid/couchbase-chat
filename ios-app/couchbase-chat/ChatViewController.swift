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

    @IBOutlet weak var textField: UITextField!
    private var liveQuery: CBLLiveQuery?

    var database: CBLDatabase = {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let db = app.database

        db.viewNamed("messages").setMapBlock("2") { (doc, emit) in
            if let type = doc["type"] as? String where type == "message" {
                if let room = doc["room"] as? String,
                    let date = doc["created_at"] as? String,
                    let message = doc["message"] as? String {
                    emit([room, date], message)
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

            if let live = liveQuery {
                live.removeObserver(self, forKeyPath: "rows")
            }

            let view = database.viewNamed("messages")
            let query = view.createQuery()
            query.startKey = [self.chatroom!]
            query.endKey = [self.chatroom!, [:]]
            let live = query.asLiveQuery()

            live.addObserver(self, forKeyPath: "rows", options: [], context: nil)

            liveQuery = live
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    deinit {
        liveQuery?.removeObserver(self, forKeyPath: "rows")
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        self.tableView.reloadData()
    }

    @IBAction func sendClick(sender: UIButton) {
        sendMessage()
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        sendMessage()

        return true
    }

    func sendMessage() {
        let text = textField.text

        if text == nil || text?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) <= 0 {
            return
        }

        let message = text!

        let properties = [
            "type": "message",
            "room": self.chatroom!,
            "created_at": CBLJSON.JSONObjectWithDate(NSDate()),
            "message": message
        ];

        let doc = database.createDocument()
        try! doc.putProperties(properties)
        
        textField.text = ""
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
        let cellIdentifier = "messageCell"

        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell!

        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: cellIdentifier)
        }

        if let cell = cell,
            let row = liveQuery?.rows?.rowAtIndex(UInt(indexPath.row)),
            let message = row.value as? String {

            cell.textLabel!.text = message
        }

        return cell

    }

}
