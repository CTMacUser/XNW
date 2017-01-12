//
//  EditableMessageViewController.swift
//  XNW
//
//  Created by Daryle Walker on 1/8/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Cocoa


class EditableMessageViewController: NSViewController {

    // MARK: Properties

    /// Whether the data can be changed through this view.
    dynamic var isWritable: Bool = true

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}
