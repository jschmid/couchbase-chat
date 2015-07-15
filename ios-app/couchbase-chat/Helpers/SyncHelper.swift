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
    private let syncURL: NSURL = kServerDbURL
    let username: String
    private let password: String
    private let creds: NSURLCredential

    private var push: CBLReplication?
    private var pull: CBLReplication?

    lazy var database: CBLDatabase = {
        return self.store.database
        }()

    init(username: String, password: String) {
        self.username = username
        self.password = password
        self.creds = NSURLCredential(user: username, password: password, persistence: .Permanent)
            let prefs = NSUserDefaults.standardUserDefaults()
            prefs.setObject("ForestDB", forKey: "CBLStorageType")
            prefs.synchronize()
    }

    func start() {
        push = database.createPushReplication(syncURL)!
        pull = database.createPullReplication(syncURL)!
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
        return ctx
        }()

    //    /**
    //    Returns the managed object context for the application.
    //    If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
    //    */
    //    - (NSManagedObjectContext *)managedObjectContext {
    //
    //    if (managedObjectContext != nil) {
    //    return managedObjectContext;
    //    }
    //
    //    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    //    if (coordinator != nil) {
    //    managedObjectContext = [NSManagedObjectContext new];
    //    [managedObjectContext setPersistentStoreCoordinator: coordinator];
    //    }
    //
    //    #if USE_COUCHBASE
    //    CBLIncrementalStore *store = (CBLIncrementalStore*)[coordinator persistentStores][0];
    //    [store addObservingManagedObjectContext:managedObjectContext];
    //    #endif
    //
    //    return managedObjectContext;
    //    }

    lazy var managedObjectModel: NSManagedObjectModel = {

        let model = NSManagedObjectModel.mergedModelFromBundles(nil)!

        CBLIncrementalStore.updateManagedObjectModel(model)

        return model

        }()


    //    /**
    //    Returns the managed object model for the application.
    //    If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
    //    */
    //    - (NSManagedObjectModel *)managedObjectModel {
    //
    //    if (managedObjectModel != nil) {
    //    return managedObjectModel;
    //    }
    //    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    //
    //    #if USE_COUCHBASE
    //    [CBLIncrementalStore updateManagedObjectModel:managedObjectModel];
    //    #endif
    //
    //    return managedObjectModel;
    //    }

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)

        return coordinator

        }()

    lazy var store: CBLIncrementalStore = {

        let storeUrl = NSURL(string: kDatabaseName)

        let thing = try! self.persistentStoreCoordinator.addPersistentStoreWithType(CBLIncrementalStore.type(), configuration: nil, URL: storeUrl, options: nil)

        let store = thing as! CBLIncrementalStore

        return store
        }()

    func getDatabase() -> CBLDatabase {
        return self.store.database
    }

    //    /**
    //    Returns the persistent store coordinator for the application.
    //    If the coordinator doesn't already exist, it is created and the application's store added to it.
    //    */
    //    - (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    //
    //    if (persistentStoreCoordinator != nil) {
    //    return persistentStoreCoordinator;
    //    }
    //
    //    NSError *error;
    //    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    //
    //    NSString *databaseName = @"recipes";
    //    NSURL *storeUrl = [NSURL URLWithString:databaseName];
    //
    //    CBLIncrementalStore *store;
//
//    store = (CBLIncrementalStore*)[persistentStoreCoordinator addPersistentStoreWithType:[CBLIncrementalStore type]
//    configuration:nil
//    URL:storeUrl options:nil error:&error];

    //
    //    if (!store) {
    //    /*
    //    Replace this implementation with code to handle the error appropriately.
    //
    //    abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
    //
    //    Typical reasons for an error here include:
    //    * The persistent store is not accessible
    //    * The schema for the persistent store is incompatible with current managed object model
    //    Check the error message to determine what the actual problem was.
    //    */
    //    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    //    abort();
    //    }
    //
    //    #if USE_COUCHBASE
    //    NSURL *remoteDbURL = [NSURL URLWithString:COUCHBASE_SYNC_URL];
    //    [self startReplication:[store.database createPullReplication:remoteDbURL]];
    //    [self startReplication:[store.database createPushReplication:remoteDbURL]];
    //    #endif
    //
    //    return persistentStoreCoordinator;
    //    }


    //    #if USE_COUCHBASE
    //    /**
    //    * Utility method to configure, start and observe a replication.
    //    */
    //    - (void)startReplication:(CBLReplication *)repl {
    //    repl.continuous = YES;
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(replicationProgress:)
    //    name:kCBLReplicationChangeNotification object:repl];
    //    [repl start];
    //    }
    //
    //    static BOOL sReplicationAlertShowing;
    //
    //    /**
    //    Observer method called when the push or pull replication's progress or status changes.
    //    */
    //    - (void)replicationProgress:(NSNotification *)notification {
    //    CBLReplication *repl = notification.object;
    //    NSError* error = repl.lastError;
    //    NSLog(@"%@ replication: status = %d, progress = %u / %u, err = %@",
    //    (repl.pull ? @"Pull" : @"Push"), repl.status, repl.changesCount, repl.completedChangesCount,
    //    error.localizedDescription);
    //
    //    if (error && !sReplicationAlertShowing) {
    //    NSString* msg = [NSString stringWithFormat: @"Sync failed with an error: %@", error.localizedDescription];
    //    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Sync Error"
    //    message: msg
    //    delegate: self
    //    cancelButtonTitle: @"Sorry"
    //    otherButtonTitles: nil];
    //    sReplicationAlertShowing = YES;
    //    [alert show];
    //    }
    //    }
    //
    //    - (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    //    sReplicationAlertShowing = NO;
    //    }
    //    #endif
    
    lazy var applicationDocumentsDirectory : String = {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true).first!
        }()
    
    //    /**
    //    Returns the path to the application's documents directory.
    //    */
    //    - (NSString *)applicationDocumentsDirectory {
    //    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    //    }
}
