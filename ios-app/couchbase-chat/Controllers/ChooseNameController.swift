//
//  ChooseNameController.swift
//  couchbase-chat
//
//  Created by Jonas Schmid on 13/07/15.
//  Copyright © 2015 schmid. All rights reserved.
//

import UIKit

class ChooseNameController: UIViewController {

    @IBOutlet weak var roomTextField: UITextField!

    var selectedUsers: Set<String>?


    lazy var database: CBLDatabase = {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let db = app.syncHelper!.database

        return db
        }()

    override func viewDidLoad() {
        // Make sure we are in the room
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        selectedUsers?.insert(app.syncHelper!.username)
    }

    @IBAction func createClick(sender: UIBarButtonItem) {
        createChatroom()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    private func createChatroom() {
        let text = roomTextField.text

        if text == nil || text?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) <= 0 {
            return
        }

        let roomname = text!
        let members = Array(selectedUsers!)
        let app = UIApplication.sharedApplication().delegate as! AppDelegate

        let properties: [String: AnyObject] = [
            "type": "chatroom",
            "name": roomname,
            "user": app.syncHelper!.username,
            "members": members
        ]

        let doc = database.createDocument()
        try! doc.putProperties(properties)
    }
}
