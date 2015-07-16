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

    lazy var database: CBLDatabase = {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let db = app.syncHelper!.database
        return db
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? ChatViewController

            let navigationController = controllers.last as! UINavigationController
            navigationController.topViewController!.navigationItem.leftBarButtonItem = split.displayModeButtonItem()
            let app = UIApplication.sharedApplication().delegate as! AppDelegate
            split.delegate = app
        }

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching")
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    func insertNewObject(sender: AnyObject) {
        let newChatroom = database.createDocument()
        let properties = ["type": "chatroom", "name": "from code"]

        do {
            try newChatroom.putProperties(properties)
        } catch {
            print("Could not create a new room")
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        self.tableView.reloadData()
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ChatViewController
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true

                if let chatroom = fetchedResultsController.objectAtIndexPath(indexPath) as? Chatroom {
                    let objId = chatroom.objectID
                    let url = objId.URIRepresentation()
                    let last = url.lastPathComponent

                    if let roomId = last {
                        // Example CBLIncrementalStore ID: pCBL-x6fcpzeUc3v8IoL_7CGR4J
                        let index = advance(roomId.startIndex, 4)
                        let CBLID = roomId.substringFromIndex(index)

                        controller.chatroomId = CBLID
                    }
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }

        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection sectionIdx: Int) -> Int {

        if let sections = fetchedResultsController.sections {
            let section = sections[sectionIdx]
            return section.numberOfObjects
        }

        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        if let chatroom = fetchedResultsController.objectAtIndexPath(indexPath) as? Chatroom {
            cell.textLabel?.text = chatroom.name
        }

        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {

            if let chatroom = fetchedResultsController.objectAtIndexPath(indexPath) as? Chatroom {
                let app = UIApplication.sharedApplication().delegate as! AppDelegate
                let ctx = app.syncHelper!.managedObjectContext

                ctx.deleteObject(chatroom)

                do {
                    try ctx.save()
                } catch {
                    print("Could not delete chatroom")
                }
            }

        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }

    // MARK: - Core Data

    lazy var fetchedResultsController: NSFetchedResultsController = {

        let fetchRequest = NSFetchRequest(entityName: "Chatroom")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]


        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let syncHelper = app.syncHelper!

        let ctrl = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: syncHelper.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

        return ctrl

        }()

//    - (NSFetchedResultsController *)fetchedResultsController {
//    // Set up the fetched results controller if needed.
//    if (fetchedResultsController == nil) {
//    // Create the fetch request for the entity.
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    // Edit the entity name as appropriate.
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Recipe" inManagedObjectContext:managedObjectContext];
//    [fetchRequest setEntity:entity];
//
//    // Edit the sort key as appropriate.
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
//    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
//
//    [fetchRequest setSortDescriptors:sortDescriptors];
//
//    // Edit the section name key path and cache name if appropriate.
//    // nil for section name key path means "no sections".
//    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
//    aFetchedResultsController.delegate = self;
//    self.fetchedResultsController = aFetchedResultsController;
//
//    }
//
//    return fetchedResultsController;
//    }


}

