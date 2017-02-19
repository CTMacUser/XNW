//
//  MessageDocument.swift
//  XNW
//
//  Created by Daryle Walker on 1/7/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Cocoa
import CoreData
import InternetMessages


class MessageDocument: NSDocument {

    enum Names {
        static let internationalEmailMessageUTI = Bundle.main.bundleIdentifier! + ".email"
        static let messageModelBundleResource = "RawMessagesModel"
    }

    // MARK: Properties

    /// Specifies an in-memory store for the message data.
    private static let storeDescription: NSPersistentStoreDescription = {
        let description = NSPersistentStoreDescription(url: URL(string: "file:///dev/null")!)
        description.url = nil
        description.type = NSInMemoryStoreType
        return description
    }()
    /// A random name tag for the data container.
    private static let containerName = String(describing: MessageDocument.self)
    /// Specifies the model for the message data.
    private static let messageModel: NSManagedObjectModel = {
        let modelBundle = Bundle(for: RawMessage.self)
        let modelURL = modelBundle.url(forResource: Names.messageModelBundleResource, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    /// The data stack for the message.
    let container: NSPersistentContainer
    /// The message.
    dynamic var message: RawMessage!
    /// The last error generated by `init()`, which can't throw errors.
    fileprivate var initError: Error?

    // MARK: Overrides

    override init() {
        self.container = NSPersistentContainer(name: MessageDocument.containerName, managedObjectModel: MessageDocument.messageModel)
        super.init()

        // Override the store type and initialize the Core Data stack.
        self.container.persistentStoreDescriptions = [MessageDocument.storeDescription]
        self.container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                self.initError = error
            }
        }

        // Finish preparing the main context and seed the root message object.
        let mainContext = container.viewContext
        mainContext.performAndWait {
            self.message = RawMessage(context: mainContext)
            do {
                try mainContext.save()
            } catch let saveError {
                self.initError = saveError
            }
        }
        mainContext.automaticallyMergesChangesFromParent = true
        mainContext.undoManager = self.undoManager
    }

    override func makeWindowControllers() {
        // Use the editable template for messages coming from files.
        self.makeMessageWindow()
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

// MARK: Initializer Overloads

extension MessageDocument {

    /// Recreate the initializer with a type name, plus extra error-checking from `init`.
    convenience init(type typeName: String) throws {
        self.init()
        guard self.initError == nil else { throw self.initError! }

        // Recreate the algorithm from super, since Swift's rules prevent me from calling it directly.
        self.fileType = typeName

        // Add some sample data
        self.undoManager?.disableUndoRegistration()
        defer {
            self.undoManager?.enableUndoRegistration()
        }
        let mainContext = container.viewContext
        mainContext.performAndWait {
            let field1 = RawHeaderField(context: mainContext)
            field1.name = "Hello"
            field1.body = "World"
            self.message.addToHeader(field1)

            let field2 = RawHeaderField(context: mainContext)
            field2.name = "Bye"
            field2.body = "planet"
            self.message.addToHeader(field2)

            self.message.body = "Is this an accurate test?"
        }
        try mainContext.save()
    }

    /// Recreate the initializer with a URL and type name, plus extra error-checking from `init`.
    convenience init(contentsOf url: URL, ofType typeName: String) throws {
        self.init()
        guard self.initError == nil else { throw self.initError! }

        // Recreate the algorithm from super, since Swift's rules prevent me from calling it directly.
        try self.read(from: url, ofType: typeName)
        self.fileURL = url
        self.fileType = typeName
        self.fileModificationDate = try FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
    }

    /// Recreate the initializer with an alternate URL, plus extra error-checking from `init`.
    convenience init(for urlOrNil: URL?, withContentsOf contentsURL: URL, ofType typeName: String) throws {
        self.init()
        guard self.initError == nil else { throw self.initError! }

        // Recreate the algorithm from super, since Swift's rules prevent me from calling it directly.
        try self.read(from: contentsURL, ofType: typeName)
        self.fileURL = urlOrNil
        self.autosavedContentsFileURL = contentsURL
        self.fileType = typeName
        self.fileModificationDate = try FileManager.default.attributesOfItem(atPath: (urlOrNil ?? contentsURL).path)[.modificationDate] as? Date
        if urlOrNil != contentsURL {
            self.updateChangeCount(.changeReadOtherContents)
        }
    }

}

// MARK: Window Creation

extension MessageDocument {

    /// Create a window (and controller) for messages.
    func makeMessageWindow() {
        let storyboard = NSStoryboard(name: MessageViewController.Names.storyboard, bundle: nil)
        let windowController = storyboard.instantiateInitialController() as! NSWindowController
        let viewController = windowController.contentViewController as! MessageViewController
        viewController.bind(#keyPath(MessageViewController.representedObject), to: self, withKeyPath: #keyPath(message), options: nil)  // Undone in the view controller.
        viewController.isWritable = !self.isInViewingMode
        windowController.window?.delegate = viewController
        self.addWindowController(windowController)
    }

}

// MARK: - Actions

extension MessageDocument {

    /// Add an empty string as the message body if it doesn't exist yet.
    @IBAction func addBody(_ sender: Any) {
        guard self.message.body == nil else { return }

        self.message.body = ""
    }

    /// Remove the message body.
    @IBAction func removeBody(_ sender: Any) {
        Swift.print("\(#function) activated.")
        self.message.body = nil
    }

}
