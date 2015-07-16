//
//  SyncHelper.swift
//  couchbase-chat
//
//  Created by Jonas Schmid on 13/07/15.
//  Copyright © 2015 schmid. All rights reserved.
//

import Foundation

private let kDatabaseName = "couchbase-chat"
private let kServerDbURL = NSURL(string: "http://192.168.1.41:4984/couchbase-chat/")!

class SyncHelper: NSObject {
    let username: String
    private let password: String
    private let creds: NSURLCredential

    private var push: CBLReplication?
    private var pull: CBLReplication?

    lazy var database: CBLDatabase = {
        let store = self.persistentStoreCoordinator.persistentStores.first as? CBLIncrementalStore
        return store!.database
        }()

    init(username: String, password: String) {
        self.username = username
        self.password = password
        self.creds = NSURLCredential(user: username, password: password, persistence: .Permanent)
    }

    func start() {
        push = database.createPushReplication(kServerDbURL)!
        pull = database.createPullReplication(kServerDbURL)!
        setupReplication(push!)
        setupReplication(pull!)
        push?.start()
        pull?.start()
    }

    func setupReplication(replication: CBLReplication) {
        replication.continuous = true
        replication.credential = creds

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "replicationProgress:", name: kCBLReplicationChangeNotification, object: replication)
    }

    private var lastSyncError: NSError?
    func replicationProgress(n: NSNotification) {
        if let pull = pull, let push = push {
            if (pull.status == CBLReplicationStatus.Active || push.status == CBLReplicationStatus.Active) {
                // Sync is active -- aggregate the progress of both replications and compute a fraction:
                let completed = pull.completedChangesCount + push.completedChangesCount
                let total = pull.changesCount + push.changesCount
                print("SYNC progress: \(completed) / \(total)")
            }

            // Check for any change in error status and display new errors:
            let error = pull.lastError ?? push.lastError
            if (error != lastSyncError) {
                lastSyncError = error
                if error != nil {
                    print("Error syncing", forError: error)
                }
            }
        }
    }

    // MARK: - Core Data

    lazy var managedObjectContext: NSManagedObjectContext = {
        let ctx = NSManagedObjectContext()
        ctx.persistentStoreCoordinator = self.persistentStoreCoordinator

        if let store = self.persistentStoreCoordinator.persistentStores.first as? CBLIncrementalStore {
            store.addObservingManagedObjectContext(ctx)
        }

        return ctx
        }()

    lazy var managedObjectModel: NSManagedObjectModel = {

        let model = NSManagedObjectModel.mergedModelFromBundles(nil)!

        CBLIncrementalStore.updateManagedObjectModel(model)

        return model

        }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)

        let storeUrl = NSURL(string: kDatabaseName)

        do {
            try coordinator.addPersistentStoreWithType(CBLIncrementalStore.type(), configuration: nil, URL: storeUrl, options: nil)
        } catch {
            print("Could not create store")
        }

        return coordinator
        }()
}
