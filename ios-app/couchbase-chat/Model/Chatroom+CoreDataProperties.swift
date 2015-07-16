//
//  Chatroom+CoreDataProperties.swift
//  couchbase-chat
//
//  Created by Jonas Schmid on 15/07/15.
//  Copyright © 2015 schmid. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Chatroom {

    @NSManaged var user: String?
    @NSManaged var members: NSData?
    @NSManaged var name: String?
    @NSManaged var messages: Message?

}
