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
        return db
        }()

    lazy var queryBuilder: CBLQueryBuilder = {
        let builder = CBLQueryBuilder(database: self.database, select: ["username"], `where`: "type == 'user'", orderBy: ["username"], error: nil)
        return builder
        }()

    override func viewDidLoad() {
        let query = self.queryBuilder.createQueryWithContext(nil)
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
        let username = user?.key as! String

        let selected = selectedUsers.contains(username)

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
        let username = user?.key as! String

        let oldElement = selectedUsers.remove(username)

        // The user was not removed, add it
        if oldElement == nil {
            selectedUsers.insert(username)
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
