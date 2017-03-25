//
//  MessageWindowController.swift
//  XNW
//
//  Created by Daryle Walker on 3/23/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Cocoa
import InternetMessages


/// Controller for messages connected to a file.
class MessageWindowController: NSWindowController {

    enum Names {
        static let storyboard = "MessageWindow"
    }

    // MARK: Properties

    /// The message to mirror.
    dynamic var representedMessage: RawMessage?
    /// Whether the message should be edited through this window
    dynamic var isWritable: Bool = true

    // Outlets
    @IBOutlet weak var messageController: NSObjectController!
    @IBOutlet weak var headerController: NSArrayController!

    // Pseudo-outlets
    var headerViewController: NSViewController!
    var bodyViewController: NSTabViewController!
    var addBodyViewController: NSViewController!
    var bodyTextViewController: NSViewController!

    var headerTableView: NSTableView!
    var bodyTextView: NSTextView!

    // MARK: Overrides, lifetime management

    deinit {
        unbind(#keyPath(isWritable))  // Bound in the document class
        unbind(#keyPath(representedMessage))  // Bound in the document class
    }

    // MARK: Overrides, window controller

    override func windowDidLoad() {
        super.windowDidLoad()

        // Attach references to the inner view controllers and views.
        let splitViewController = contentViewController as! NSSplitViewController
        headerViewController = splitViewController.splitViewItems.first!.viewController 
        bodyViewController = splitViewController.splitViewItems.last?.viewController as! NSTabViewController
        addBodyViewController = bodyViewController.tabViewItems.first!.viewController
        bodyTextViewController = bodyViewController.tabViewItems.last!.viewController

        let headerScrollView = headerViewController.view.subviews.first as! NSScrollView
        let bodyScrollView = bodyTextViewController.view.subviews.first as! NSScrollView
        headerTableView = headerScrollView.documentView as! NSTableView
        bodyTextView = bodyScrollView.documentView as! NSTextView

        // Attach the message-object and header controllers to the view-controllers.
        for controller in [bodyViewController, addBodyViewController, bodyTextViewController] {
            controller?.bind(#keyPath(NSViewController.representedObject), to: self, withKeyPath: #keyPath(messageController))  // Undone during window close.
        }
        headerViewController.bind(#keyPath(NSViewController.representedObject), to: self, withKeyPath: #keyPath(headerController))  // Undone during window close.

    }

}

// MARK: - Window Delegate

extension MessageWindowController: NSWindowDelegate {

    // Watch for window-close to know when to unbind.
    func windowWillClose(_ notification: Notification) {
        guard self.window === (notification.object as? NSWindow) else { return }

        for controller in [self.headerViewController, self.bodyTextViewController, self.addBodyViewController, self.bodyViewController] {
            controller?.unbind(#keyPath(NSViewController.representedObject))  // Bound in windowDidLoad.
        }
    }

    // Use the document's undo manager.
    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
        return window === self.window ? self.document?.undoManager : nil
    }

}
