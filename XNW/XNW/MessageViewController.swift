//
//  MessageViewController.swift
//  XNW
//
//  Created by Daryle Walker on 2/16/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Cocoa
import CoreData
import InternetMessages


class MessageViewController: NSViewController {

    enum Names {
        static let storyboard = "MessageWindow"
    }

    // MARK: Properties

    fileprivate static var kvoContext = 0

    // Outlets
    @IBOutlet weak var messagePartsTabView: NSTabView!
    @IBOutlet weak var headerTabItem: NSTabViewItem!
    @IBOutlet weak var bodyTabItem: NSTabViewItem!

    /// The represented message.
    dynamic var representedMessage: RawMessage? {
        return self.representedObject as? RawMessage
    }
    /// The managed object context for the represented object.
    dynamic var managedObjectContext: NSManagedObjectContext? {
        return self.representedMessage?.managedObjectContext
    }
    /// Whether the message can be edited through this window.
    dynamic var isWritable: Bool = true

    // Confirm if observation of the message body is occuring.  There is no method to check, yet you can't remove links that haven't been added.
    fileprivate var isObservingMessageBody = false

    /// Whether the view-header button should be active.
    dynamic fileprivate(set) var isViewHeaderButtonActive: Bool = false
    /// Whether the view-body button should be active.
    dynamic fileprivate(set) var isViewBodyButtonActive: Bool = true

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.window?.delegate = self
        assert(self.messagePartsTabView.selectedTabViewItem == self.headerTabItem)
    }

    override var representedObject: Any? {
        willSet {
            guard self.isObservingMessageBody else { return }

            (super.representedObject as AnyObject).removeObserver(self, forKeyPath: #keyPath(RawMessage.body), context: &MessageViewController.kvoContext)
            self.isObservingMessageBody = false
        }

        didSet {
            (super.representedObject as AnyObject).addObserver(self, forKeyPath: #keyPath(RawMessage.body), options: [.initial], context: &MessageViewController.kvoContext)
            self.isObservingMessageBody = true
        }
    }

    // MARK: KVO/KVC stuff

    /// Returns the attributes that affect the represented message.
    class func keyPathsForValuesAffectingRepresentedMessage() -> Set<String> {
        return [#keyPath(MessageViewController.representedObject)]
    }

    /// Returns the attributes that affect the managed context.
    class func keyPathsForValuesAffectingManagedObjectContext() -> Set<String> {
        return [#keyPath(MessageViewController.representedMessage)]
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &MessageViewController.kvoContext else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }

        if keyPath == #keyPath(RawMessage.body) && (object as? RawMessage) == self.representedMessage {
            // Make sure the body tab is never shown when the message body is `nil`.
            if self.representedMessage?.body == nil {
                self.messagePartsTabView.selectTabViewItem(self.headerTabItem)
            }
        } else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

}

// MARK: - Actions

extension MessageViewController {

    /// Set the tab for the header table to be active.
    @IBAction func viewHeader(_ sender: NSButton) {
        self.messagePartsTabView.selectTabViewItem(self.headerTabItem)
    }

    /// Set the tab for the body text to be active.
    @IBAction func viewBody(_ sender: NSButton) {
        self.messagePartsTabView.selectTabViewItem(self.bodyTabItem)
    }

}

// MARK: Tab Delegate

extension MessageViewController: NSTabViewDelegate {

    // Don't let a `nil` message body be directly edited.
    func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        assert(tabView == self.messagePartsTabView)

        return self.representedMessage?.body != nil || tabViewItem != self.bodyTabItem
    }

    // A button for a tab should be inactive while its tab is visible.
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        assert(tabView == self.messagePartsTabView)

        self.isViewHeaderButtonActive = tabViewItem != self.headerTabItem
        self.isViewBodyButtonActive = tabViewItem != self.bodyTabItem
    }

}

// MARK: - Window Delegate

extension MessageViewController: NSWindowDelegate {

    // Watch for window-close to know when to unbind.
    func windowWillClose(_ notification: Notification) {
        self.unbind(#keyPath(representedObject))  // Linked in document class.

        if self.isObservingMessageBody {
            self.representedMessage?.removeObserver(self, forKeyPath: #keyPath(RawMessage.body), context: &MessageViewController.kvoContext)
            self.isObservingMessageBody = false
        }
    }

}
