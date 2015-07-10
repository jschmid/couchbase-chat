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

    var database: CBLDatabase = {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let db = app.database

        db.viewNamed("chatrooms").setMapBlock("1") { (doc, emit) in
            if let type = doc["type"] as? String where type == "chatroom" {
                if let name = doc["name"] as? String {
                    emit(name, nil)
                }
            }
        }

        return db
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? ChatViewController
        }

        // Init datasource

        let query = database.viewNamed("chatrooms").createQuery()
        let live = query.asLiveQuery()
        live.descending = true

        liveQuery = live

        // Magic line
        live.waitForRows()

        if let rows = live.rows {
            for row in rows {
                print(row)
            }
        } else if let error = live.lastError {
            print("Error")
            print(error)
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    func insertNewObject(sender: AnyObject) {
//        objects.insert(NSDate(), atIndex: 0)
//        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
//        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

        let newChatroom = database.createDocument()
        let properties = ["type": "chatroom", "name": "from code"]

        do {
            try newChatroom.putProperties(properties)
        } catch {
            print("Could not create a new room")
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ChatViewController
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true

                if let row = liveQuery?.rows?.rowAtIndex(UInt(indexPath.row)),
                    let name = row.key as? String {
                        controller.detailItem = name
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
//            objects.removeAtIndex(indexPath.row)
//            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

