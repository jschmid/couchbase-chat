//
//  ChooseUsersController.swift
//  couchbase-chat
//
//  Created by Jonas Schmid on 13/07/15.
//  Copyright © 2015 schmid. All rights reserved.
//

import UIKit

class ChooseUsersController: UITableViewController {

    var users: CBLQueryEnumerator?
    var selectedUsers = Set<String>()

    lazy var database: CBLDatabase = {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let db = app.syncHelper!.database

        db.viewNamed("users").setMapBlock("1") { (doc, emit) in
            if let type = doc["type"] as? String where type == "user" {
                if let username = doc["username"] as? String, let docId = doc["_id"] {
                    emit(username, docId)
                }
            }
        }

        return db
        }()

    override func viewDidLoad() {

        let query = database.viewNamed("users").createQuery()

        users = try! query.run()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = users?.count {
            return Int(count)
        }

        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("username", forIndexPath: indexPath)

        let user = users?.rowAtIndex(UInt(indexPath.row))
        let userId = user?.value as! String
        let username = user?.key as! String

        let selected = selectedUsers.contains(userId)

        if selected {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        cell.textLabel?.text = username

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        let user = users?.rowAtIndex(UInt(indexPath.row))
        let userId = user?.value as! String

        let oldElement = selectedUsers.remove(userId)

        // The user was not removed, add it
        if oldElement == nil {
            selectedUsers.insert(userId)
        }

        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "chooseName" {
            let ctrl = segue.destinationViewController as? ChooseNameController
            ctrl?.selectedUsers = selectedUsers
        }
    }

}
