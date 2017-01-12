//
//  MessageDocument.swift
//  XNW
//
//  Created by Daryle Walker on 1/7/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Cocoa


class MessageDocument: NSDocument {

    enum Names {
        static let internationalEmailMessageUTI = Bundle.main.bundleIdentifier! + ".email"
    }

    class TrialField: NSObject {
        dynamic var name: String
        dynamic var body: String

        init(name: String, body: String) {
            self.name = name
            self.body = body
        }
    }
    class TrialMessage: NSObject {
        dynamic var header: [TrialField]
        dynamic var body: String?

        init(fields: TrialField..., body: String? = nil) {
            self.header = fields
            self.body = body
        }
    }

    // MARK: Properties

    dynamic var message: TrialMessage {
        didSet {
            Swift.print("Changed the message.")
            for controller in self.windowControllers {
                if let editingController = controller as? EditableMessageWindowController {
                    editingController.message = message
                }
            }
        }
    }

    // MARK: Overrides

    override init() {
        self.message = TrialMessage(fields: TrialField(name: "Hello", body: "There"), TrialField(name: "Goodbye", body: "World"), body: "This is a test.")
        super.init()
        // Add your subclass-specific initialization here.
    }

    override func makeWindowControllers() {
        // Use the editable template for messages coming from files.
        self.makeMessageEditWindow()
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    // MARK: Window Creation

    /// Create a window (and controller) for editing messages.
    func makeMessageEditWindow() {
        let storyboard = NSStoryboard(name: EditableMessageWindowController.Names.storyboard, bundle: nil)
        let controller = storyboard.instantiateInitialController() as! EditableMessageWindowController
        controller.message = self.message
        controller.isWritable = self.isInViewingMode
        self.addWindowController(controller)
    }

}
