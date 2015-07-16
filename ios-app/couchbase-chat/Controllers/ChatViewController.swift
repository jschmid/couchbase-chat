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

    lazy var database: CBLDatabase = {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let db = app.syncHelper!.database

        db.viewNamed("messages").setMapBlock("3") { (doc, emit) in
            if let type = doc["type"] as? String where type == "Message" {
                if let room = doc["room"] as? String,
                    let date = doc["created_at"] as? String,
                    let username = doc["user"] as? String,
                    let message = doc["message"] as? String {
                    emit([room, date], [username, message])
                }
            }
        }

        return db
        }()

    lazy var username: String = {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        return app.syncHelper!.username
    }()


    var chatroomId: String? {
        didSet {
            if let chatroomId = self.chatroomId {
                chatroomDoc = database.documentWithID(chatroomId)
            }
            if editingMessage != nil {
                editingMessage = nil
            }
            self.configureView()
        }
    }
    var chatroomDoc: CBLDocument?

    var editingMessage: CBLDocument? {
        didSet {
            if let doc = editingMessage {
                self.textField.text = doc["message"] as? String
                self.textField.selectAll(nil)
                self.textField.becomeFirstResponder()
            } else {
                self.textField.text = ""
            }
        }
    }

    func configureView() {
        if let roomId = self.chatroomId,
            let chatroom = self.chatroomDoc {

            let roomname = chatroom["name"] as? String
            self.title = roomname

            if let live = liveQuery {
                live.removeObserver(self, forKeyPath: "rows")
            }

            let view = database.viewNamed("messages")
            let query = view.createQuery()
            query.startKey = [roomId]
            query.endKey = [roomId, [:]]
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

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
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

        if let editingMessage = editingMessage {
            sendEditedMessage(editingMessage, message: message)
        } else {
            sendNewMessage(message)
        }
        
        textField.text = ""
    }

    func sendNewMessage(message: String) {
        let properties = [
            "type": "Message",
            "room": self.chatroomId!,
            "created_at": CBLJSON.JSONObjectWithDate(NSDate()),
            "user": username,
            "message": message
        ]

        let doc = database.createDocument()
        try! doc.putProperties(properties)
    }

    func sendEditedMessage(doc: CBLDocument, message: String) {
        if var newProps = doc.properties as? [String: AnyObject] {
            newProps["message"] = message
            try! doc.putProperties(newProps)

            editingMessage = nil
        }
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
            let values = row.value as? Array<String> {

                cell.textLabel!.text = values[1]
                cell.detailTextLabel!.text = values[0]

                cell.accessoryType = row.documentID == editingMessage?.documentID ? .Checkmark : .None
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if isRowFromCurrentUser(indexPath) {
            if let row = liveQuery?.rows?.rowAtIndex(UInt(indexPath.row)) {
                editingMessage = row.document
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        } else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return isRowFromCurrentUser(indexPath)
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {

            if let row = liveQuery?.rows?.rowAtIndex(UInt(indexPath.row)) {
                let doc = row.document

                do {
                    try doc?.deleteDocument()
                } catch {
                    print("Could not delete")
                }
            }

        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }

    // MARK - Helpers

    func isRowFromCurrentUser(indexPath: NSIndexPath) -> Bool {
        if let row = liveQuery?.rows?.rowAtIndex(UInt(indexPath.row)),
            let rowValue = row.value as? [String] {
                let rowUsername = rowValue[0]
                return rowUsername == username
        } else {
            return false
        }
    }

}
