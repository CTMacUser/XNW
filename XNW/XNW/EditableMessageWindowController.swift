//
//  EditableMessageWindowController.swift
//  XNW
//
//  Created by Daryle Walker on 1/7/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Cocoa


class EditableMessageWindowController: NSWindowController {

    enum Names {
        static let storyboard = "EditableMessageWindow"
    }

    // MARK: Properties

    /// The message to be displayed in this window.
    dynamic var message: MessageDocument.TrialMessage? {
        didSet {
            self.contentViewController?.representedObject = message
        }
    }
    /// Whether the message can be edited through this window.
    dynamic var isWritable: Bool = true

    // MARK: Overrides

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        let controller = self.contentViewController as! EditableMessageViewController
        controller.bind(#keyPath(EditableMessageViewController.isWritable), to: self, withKeyPath: #keyPath(isWritable), options: nil)
    }

}

// MARK: - Window Delegate

extension EditableMessageWindowController: NSWindowDelegate {

    func windowWillClose(_ notification: Notification) {
        let controller = self.contentViewController as! EditableMessageViewController
        controller.unbind(#keyPath(EditableMessageViewController.isWritable))
    }

}
