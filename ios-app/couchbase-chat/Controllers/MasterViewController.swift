//
//  MasterViewController.swift
//  couchbase-chat
//
//  Created by Jonas Schmid on 10/07/15.
//  Copyright © 2015 schmid. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    var detailViewController: ChatViewController? = nil

    private var liveQuery: CBLLiveQuery?

    lazy var database: CBLDatabase = {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let db = app.syncHelper!.database

        db.viewNamed("chatrooms").setMapBlock("2") { (doc, emit) in
            if let type = doc["type"] as? String where type == "chatroom" {
                if let name = doc["name"] as? String, let docId = doc["_id"] {
                    emit(name, docId)
                }
            }
        }

        return db
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? ChatViewController
        }

        // Init datasource

        let query = database.viewNamed("chatrooms").createQuery()
        let live = query.asLiveQuery()
        live.descending = true

        live.addObserver(self, forKeyPath: "rows", options: [], context: nil)

        liveQuery = live
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    deinit {
        liveQuery?.removeObserver(self, forKeyPath: "rows")
    }

    func insertNewObject(sender: AnyObject) {
        let newChatroom = database.createDocument()
        let properties = ["type": "chatroom", "name": "from code"]

        do {
            try newChatroom.putProperties(properties)
        } catch {
            print("Could not create a new room")
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        self.tableView.reloadData()
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ChatViewController
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true

                if let row = liveQuery?.rows?.rowAtIndex(UInt(indexPath.row)),
                    let roomId = row.value as? String {
                        controller.chatroomId = roomId
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return liveQuery?.rows == nil ? 0 : 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if let rows = liveQuery?.rows {
            let count = rows.count
            return Int(count)
        }

        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        if let row = liveQuery?.rows?.rowAtIndex(UInt(indexPath.row)),
            let name = row.key as? String {
                cell.textLabel?.text = name
        }

        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
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


}

