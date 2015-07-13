//
//  Utilities.swift
//  couchbase-chat
//
//  Created by Jonas Schmid on 10/07/15.
//  Copyright © 2015 schmid. All rights reserved.
//

import Foundation

extension CBLView {
    // Just reorders the parameters to take advantage of Swift's trailing-block syntax.
    func setMapBlock(version: String, mapBlock: CBLMapBlock) -> Bool {
        return setMapBlock(mapBlock, version: version)
    }
}