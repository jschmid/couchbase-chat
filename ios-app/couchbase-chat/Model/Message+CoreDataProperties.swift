//
//  Message+CoreDataProperties.swift
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

extension Message {

    @NSManaged var created_at: NSDate?
    @NSManaged var user: String?
    @NSManaged var message: String?
    @NSManaged var room: Chatroom?

}
