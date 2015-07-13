//
//  LoginViewController.swift
//  couchbase-chat
//
//  Created by Jonas Schmid on 13/07/15.
//  Copyright © 2015 schmid. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        let prefs = NSUserDefaults.standardUserDefaults()

        if let username = prefs.stringForKey("username"),
            let password = prefs.stringForKey("password") {
                startLogin(username, password: password)
        }
    }

    @IBAction func signinClick(sender: UIButton) {
        if let username = usernameTextField.text,
            let password = passwordTextField.text {
                startLogin(username, password: password)
        }
    }

    private func startLogin(username: String, password: String) {
        let syncHelper = SyncHelper(username: username, password: password)

        let app = UIApplication.sharedApplication().delegate as? AppDelegate
        app?.syncHelper = syncHelper

        syncHelper.start()

        let prefs = NSUserDefaults.standardUserDefaults()
        prefs.setObject(username, forKey: "username")
        prefs.setObject(password, forKey: "password")

        // Async call because this method may be called from viewDidLoad and the performSegue will not work
        dispatch_async(dispatch_get_main_queue()) {
            self.performSegueWithIdentifier("chatSegue", sender: self)
        }
    }

}
