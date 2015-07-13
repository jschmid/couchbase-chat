//
//  AppDelegate.swift
//  couchbase-chat
//
//  Created by Jonas Schmid on 10/07/15.
//  Copyright © 2015 schmid. All rights reserved.
//

import UIKit

private let kDatabaseName = "couchbase-chat"

private let kServerDbURL = NSURL(string: "http://192.168.1.41:4984/couchbase-chat/")!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?


    private var _push: CBLReplication!
    private var _pull: CBLReplication!
    private var _syncError: NSError?

    let database: CBLDatabase!

    override init() {
        do {
            let manager = CBLManager.sharedInstance()
            try database = manager.databaseNamed(kDatabaseName)
        } catch {
            database = nil
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        if database == nil {
            print("Unable to initialize Couchbase Lite")
            return false
        }

        // Initialize replication:
        _push = setupReplication(database.createPushReplication(kServerDbURL))
        _pull = setupReplication(database.createPullReplication(kServerDbURL))
        _push.start()
        _pull.start()

        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.delegate = self
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Split view

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? ChatViewController else { return false }
        if topAsDetailController.chatroom == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }

    // MARK: - Couchbase


    func setupReplication(replication: CBLReplication!) -> CBLReplication! {
        if replication != nil {
            replication.continuous = true
            NSNotificationCenter.defaultCenter().addObserver(self,
                selector: "replicationProgress:",
                name: kCBLReplicationChangeNotification,
                object: replication)
        }
        return replication
    }


    func replicationProgress(n: NSNotification) {
        if (_pull.status == CBLReplicationStatus.Active || _push.status == CBLReplicationStatus.Active) {
            // Sync is active -- aggregate the progress of both replications and compute a fraction:
            let completed = _pull.completedChangesCount + _push.completedChangesCount
            let total = _pull.changesCount + _push.changesCount
            print("SYNC progress: \(completed) / \(total)")
        }

        // Check for any change in error status and display new errors:
        let error = _pull.lastError ?? _push.lastError
        if (error != _syncError) {
            _syncError = error
            if error != nil {
                print("Error syncing", forError: error)
            }
        }
    }


}

