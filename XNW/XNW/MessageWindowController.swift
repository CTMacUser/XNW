//
//  MessageWindowController.swift
//  XNW
//
//  Created by Daryle Walker on 4/1/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Cocoa
import InternetMessages


/// Manage a window mirroring a Message object.
class MessageWindowController: NSWindowController {

    // MARK: Support Types

    /// Contain various string constants.
    enum Names {
        static let storyboard = "MessageWindow"
    }

    // MARK: Properties

    /// The message object to represent.
    dynamic var representedMessage: RawMessage?
    /// Whether the message can be altered through this window.
    dynamic var isWritable: Bool = false

    /// The split-view controller managing the message view parts.
    var splitViewController: MessageSplitViewController! {
        return contentViewController as! MessageSplitViewController
    }

    // MARK: Overrides, NSWindowController

    override func windowDidLoad() {
        super.windowDidLoad()

        // Connect the split-view controller to the main properties.  (Undone when window closes.)
        splitViewController.bind(#keyPath(MessageSplitViewController.representedObject), to: self, withKeyPath: #keyPath(representedMessage))
        splitViewController.bind(#keyPath(MessageSplitViewController.isWritable), to: self, withKeyPath: #keyPath(isWritable))
    }

}

// MARK: Actions

extension MessageWindowController {

    // Add a body to the message.
    @IBAction func addBody(_ sender: Any) {
        self.representedMessage?.body = ""
    }

    // Remove the body from the message.
    @IBAction func removeBody(_ sender: Any) {
        self.representedMessage?.body = nil
    }

    // Add a header field to the message.
    @IBAction func addHeaderField(_ sender: Any) {
        self.splitViewController.header.headerController.add(sender)
    }

    // Remove the selected header field(s) from the message.
    @IBAction func removeHeaderField(_ sender: Any) {
        self.splitViewController.header.headerController.remove(sender)
    }

}

extension MessageWindowController: NSUserInterfaceValidations {

    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard let action = item.action else { return true }

        let selectorSet = Set(arrayLiteral: #selector(addBody(_:)), #selector(removeBody(_:)), #selector(addHeaderField(_:)), #selector(removeHeaderField(_:)))
        switch action {
        case let action2 where selectorSet.contains(action2):
            guard let message = self.representedMessage, self.isWritable else { return false }

            switch action2 {
            case #selector(addBody(_:)):
                return message.body == nil
            case #selector(removeBody(_:)):
                return message.body != nil
            case #selector(addHeaderField(_:)):
                return self.splitViewController.header.headerController.canAdd
            case #selector(removeHeaderField(_:)):
                return self.splitViewController.header.headerController.canRemove
            default:
                return true
            }

        default:
            return true
        }
    }

}

// MARK: - Window Delegate

extension MessageWindowController: NSWindowDelegate {

    func windowWillClose(_ notification: Notification) {
        guard self.window === (notification.object as? NSWindow) else { return }

        // Undo connections made during `windowDidLoad()`.
        self.splitViewController.unbind(#keyPath(MessageSplitViewController.isWritable))
        self.splitViewController.unbind(#keyPath(MessageSplitViewController.representedObject))

        // Undo connections from the document subclass.
        self.unbind(#keyPath(isWritable))
        self.unbind(#keyPath(representedMessage))
    }

    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
        return window === self.window ? self.document?.undoManager : nil
    }

}

// MARK: - Controller for the Split View

/// Manage the split between the header and body sections.
class MessageSplitViewController: NSSplitViewController {

    /// Whether the message can be altered through this controller.
    dynamic var isWritable: Bool = false

    // Pseudo-outlets
    var header: MessageHeaderViewController!
    var body: MessageBodyViewController!

    // Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        header = splitViewItems.first?.viewController as! MessageHeaderViewController 
        body = splitViewItems.last?.viewController as! MessageBodyViewController
    }

    override func viewWillAppear() {
        // Connect the split views to the main properties
        header.bind(#keyPath(MessageHeaderViewController.representedObject), to: self, withKeyPath: #keyPath(representedObject))
        header.bind(#keyPath(MessageHeaderViewController.isWritable), to: self, withKeyPath: #keyPath(isWritable))
        body.bind(#keyPath(MessageBodyViewController.representedObject), to: self, withKeyPath: #keyPath(representedObject))
        body.bind(#keyPath(MessageBodyViewController.isWritable), to: self, withKeyPath: #keyPath(isWritable))
    }

    override func viewDidDisappear() {
        // Undo connections made during `viewWillAppear()`.
        body.unbind(#keyPath(MessageBodyViewController.isWritable))
        body.unbind(#keyPath(MessageBodyViewController.representedObject))
        header.unbind(#keyPath(MessageHeaderViewController.isWritable))
        header.unbind(#keyPath(MessageHeaderViewController.representedObject))
    }

}

// MARK: Controller for the Message Header

/// Manage display of the message header.
class MessageHeaderViewController: NSViewController {

    /// Contain various string constants.
    enum Names {
        static let nameColumn = "name"
        static let bodyColumn = "body"
    }

    /// Whether the message can be altered through this controller.
    dynamic var isWritable: Bool = false

    // Outlets
    @IBOutlet weak var headerTable: NSTableView!
    @IBOutlet weak var headerController: NSArrayController!

    /// The controller's view of the header array.
    dynamic var headerArray: NSMutableArray {
        return headerController.mutableArrayValue(forKey: #keyPath(NSArrayController.arrangedObjects))
    }

    // Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

}

extension MessageHeaderViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        var height = tableView.rowHeight
        guard self.headerTable === tableView, let field = self.headerArray[row] as? RawHeaderField else { return height }

        for (columnId, value) in [(Names.nameColumn, field.name), (Names.bodyColumn, field.body)] {
            guard let prototypeCell = tableView.make(withIdentifier: columnId, owner: self) as? NSTableCellView else {
                continue
            }

            let column = tableView.tableColumns[tableView.column(withIdentifier: columnId)]
            prototypeCell.textField?.stringValue = value
            prototypeCell.widthAnchor.constraint(equalToConstant: column.width).isActive = true
            prototypeCell.layoutSubtreeIfNeeded()
            height = max(height, prototypeCell.fittingSize.height)
        }
        return height
    }

    func tableViewColumnDidResize(_ notification: Notification) {
        guard self.headerTable === (notification.object as? NSTableView) else { return }

        self.headerTable.noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: 0 ..< self.headerTable.numberOfRows))
    }

}

// MARK: Controller for the Message Body

/// Manage display of the message body states.
class MessageBodyViewController: NSTabViewController {

    /// Whether the message can be altered through this controller.
    dynamic var isWritable: Bool = false

    // Pseudo-outlets
    var nilBody: MessageNilBodyViewController!
    var nonNilBody: MessageExistantBodyViewController!

    // Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        nilBody = tabViewItems.first?.viewController as! MessageNilBodyViewController
        nonNilBody = tabViewItems.last?.viewController as! MessageExistantBodyViewController
    }

    override func viewWillAppear() {
        // Connect the tabbed views to the main properties.
        nilBody.bind(#keyPath(MessageNilBodyViewController.representedObject), to: self, withKeyPath: #keyPath(representedObject))
        nilBody.bind(#keyPath(MessageNilBodyViewController.isWritable), to: self, withKeyPath: #keyPath(isWritable))
        nonNilBody.bind(#keyPath(MessageExistantBodyViewController.representedObject), to: self, withKeyPath: #keyPath(representedObject))
        nonNilBody.bind(#keyPath(MessageExistantBodyViewController.isWritable), to: self, withKeyPath: #keyPath(isWritable))
    }

    override func viewDidDisappear() {
        // Undo connections made during `viewWillAppear()`.
        nonNilBody.unbind(#keyPath(MessageExistantBodyViewController.isWritable))
        nonNilBody.unbind(#keyPath(MessageExistantBodyViewController.representedObject))
        nilBody.unbind(#keyPath(MessageNilBodyViewController.isWritable))
        nilBody.unbind(#keyPath(MessageNilBodyViewController.representedObject))
    }

}

// MARK: Controller for Message Body in the NIL State

/// Manage a NIL message body, and the button to change it.
class MessageNilBodyViewController: NSViewController {

    /// Whether the message can be altered through this controller.
    dynamic var isWritable: Bool = false

    // Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

}

// MARK: Controller for Message Body in a Valid State

/// Manage a valid message body.
class MessageExistantBodyViewController: NSViewController {

    /// Whether the message can be altered through this controller.
    dynamic var isWritable: Bool = false

    // Outlets
    @IBOutlet var bodyText: NSTextView!

    // Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

}
