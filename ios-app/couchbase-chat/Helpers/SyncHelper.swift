//
//  SyncHelper.swift
//  couchbase-chat
//
//  Created by Jonas Schmid on 13/07/15.
//  Copyright © 2015 schmid. All rights reserved.
//

import Foundation

private let kDatabaseName = "couchbase-chat"

class SyncHelper: NSObject {
    private let syncURL: NSURL
    private let username: String
    private let password: String
    private let creds: NSURLCredential

    private let push: CBLReplication
    private let pull: CBLReplication

    let database: CBLDatabase!

    init(syncURL: NSURL, username: String, password: String) {
        self.syncURL = syncURL
        self.username = username
        self.password = password
        self.creds = NSURLCredential(user: username, password: password, persistence: .Permanent)

        do {
            let manager = CBLManager.sharedInstance()
            try self.database = manager.databaseNamed(kDatabaseName)
        } catch {
            database = nil
        }

        push = database.createPushReplication(syncURL)!
        pull = database.createPullReplication(syncURL)!
    }

    func start() {
        setupReplication(push)
        setupReplication(pull)
        push.start()
        pull.start()
    }

    func setupReplication(replication: CBLReplication) {
        replication.continuous = true
        replication.credential = creds

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "replicationProgress:", name: kCBLReplicationChangeNotification, object: replication)
    }

    private var _syncError: NSError?
    func replicationProgress(n: NSNotification) {
        if (pull.status == CBLReplicationStatus.Active || push.status == CBLReplicationStatus.Active) {
            // Sync is active -- aggregate the progress of both replications and compute a fraction:
            let completed = pull.completedChangesCount + push.completedChangesCount
            let total = pull.changesCount + push.changesCount
            print("SYNC progress: \(completed) / \(total)")
        }

        // Check for any change in error status and display new errors:
        let error = pull.lastError ?? push.lastError
        if (error != _syncError) {
            _syncError = error
            if error != nil {
                print("Error syncing", forError: error)
            }
        }
    }
}
