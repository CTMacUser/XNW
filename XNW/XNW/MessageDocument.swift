//
//  MessageDocument.swift
//  XNW
//
//  Created by Daryle Walker on 4/28/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import Cocoa


class MessageDocument: NSDocument {

    /// Collection of various resource identifier strings used in the implementation.
    enum Names {
        static let storyboard = "MessageDocument"
        static let messageWindow = "message-window"
        static let primaryUTI = NSBundle.mainBundle().bundleIdentifier!.stringByAppendingString(".email")
        static let secondaryUTI = "com.apple.mail.email"
        static let coreMessageUTI = "public.utf8-mail-message"
    }

    /// The stored message (i.e. the data/model).
    dynamic var message: RegularInternetMessage

    override init() {
        message = RegularInternetMessage()
        super.init()
        // Add your subclass-specific initialization here.
    }

    override func makeWindowControllers() {
        let storyboard = NSStoryboard(name: Names.storyboard, bundle: nil)
        let controller = storyboard.instantiateControllerWithIdentifier(Names.messageWindow) as! MessageWindowController
        self.addWindowController(controller)

        controller.contentViewController?.representedObject = message
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
        print(#function + "got called.")
    }

    override func dataOfType(typeName: String) throws -> NSData {
        assert(UTTypeConformsTo(typeName, kUTTypeEmailMessage) || UTTypeConformsTo(typeName, Names.coreMessageUTI))
        guard let serializedData = message.binaryDescription else {
            throw NSCocoaError.FileWriteInapplicableStringEncodingError
        }
        return serializedData
        // Later: watch out when switching to Core Data, due to multithreading.
        // ...possibly override `canAsynchronouslyWriteToURL:ofType:forSaveOperation:` and use `unblockUserInteraction`.
    }

    override func readFromData(data: NSData, ofType typeName: String) throws {
        assert(UTTypeConformsTo(typeName, kUTTypeEmailMessage) || UTTypeConformsTo(typeName, Names.coreMessageUTI))
        guard let newMessage = RegularInternetMessage(data: data) else {
            throw NSCocoaError.FileReadUnknownStringEncodingError
        }
        message = newMessage
        // Later: handle disabling of undo registration.
        // Later: possibly override `canConcurrentlyReadDocumentsOfType` (watch out when switching to Core Data!).
    }

    override class func autosavesInPlace() -> Bool {
        return true
        // Later: turn this off if the Core Data version saves too slow.
    }

}
