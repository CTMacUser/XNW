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
    }

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override func makeWindowControllers() {
        // Use the editable template for messages coming from files.
        let storyboard = NSStoryboard(name: EditableMessageWindowController.Names.storyboard, bundle: nil)
        let windowController = storyboard.instantiateInitialController() as! EditableMessageWindowController
        self.addWindowController(windowController)
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

}
