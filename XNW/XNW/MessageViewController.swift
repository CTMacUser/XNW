//
//  MessageViewController.swift
//  XNW
//
//  Created by Daryle Walker on 4/28/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import Cocoa

class MessageViewController: NSViewController {

    /// The table presenting the header, field names and bodies.
    @IBOutlet weak var headerTable: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

/// Controller for the inner tab-views displaying the message body string.
class MessageBodyTabViewController: NSTabViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        representedObject = (parentViewController?.representedObject as? RegularInternetMessage)?.body
    }

}

/// Controller for the tab view for NIL body strings.
class MessageBodyNilViewController: NSViewController {

    /// Signals making the message body string non-NIL.
    @IBOutlet weak var addBodyButton: NSButton!

}

/// Controller for the tab view for an active body string.
class MessageBodyTextViewController: NSViewController {

    /// Views/edits the message body string.
    @IBOutlet var bodyTextView: NSTextView!

}
