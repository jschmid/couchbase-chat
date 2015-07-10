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
    var objects = [AnyObject]()

    private var dataSource = CBLUITableSource()

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

        do {
            let enumerator = try query.run()
            for row in enumerator {
                print(row)
            }
        } catch {
            print("Could not run query")
        }

//        let liveQuery = query.asLiveQuery()
//        liveQuery.descending = true

//        dataSource.query = liveQuery
//        dataSource.labelProperty = "name"
//
//        self.tableView.dataSource = dataSource
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    func insertNewObject(sender: AnyObject) {
//        objects.insert(NSDate(), atIndex: 0)
//        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
//        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ChatViewController
                controller.detailItem = object.description
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 1
//    }
//
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 5;
//    }
//
//    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
//
//        let object = objects[indexPath.row] as! NSDate
//        cell.textLabel!.text = object.description
//        return cell
//    }
//
//    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        // Return false if you do not want the specified item to be editable.
//        return true
//    }
//
//    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        if editingStyle == .Delete {
//            objects.removeAtIndex(indexPath.row)
//            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//        } else if editingStyle == .Insert {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
//        }
//    }


}

