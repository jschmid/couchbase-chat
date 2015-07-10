//
//  ChatViewController.swift
//  couchbase-chat
//
//  Created by Jonas Schmid on 10/07/15.
//  Copyright © 2015 schmid. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {

    var detailItem: String? {
        didSet {
            self.configureView()
        }
    }

    func configureView() {
        if let detail = self.detailItem {
            self.title = detail
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }

}
