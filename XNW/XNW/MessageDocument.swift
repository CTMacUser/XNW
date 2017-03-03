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
        let mainContext = self.container.viewContext
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
        // Get a copy of the message before any main-thread actions could change it.
        var backgroundMessage: RawMessage!
        let backgroundContext = self.container.newBackgroundContext()
        backgroundContext.performAndWait {
            backgroundMessage = backgroundContext.object(with: self.message.objectID) as! RawMessage
        }
        self.unblockUserInteraction()

        // Do the type check after unlocking the main thread; don't risk deadlocking the app.
        let isTypeEmail = UTTypeConformsTo(typeName as CFString, Names.internationalEmailMessageUTI as CFString)
        guard isTypeEmail else { throw CocoaError(.fileWriteUnknown) }

        // Extract the raw data from the message.
        var messageData: Data?
        backgroundContext.performAndWait {
            messageData = backgroundMessage.messageAsExternalData
        }
        return messageData!
    }

    override func read(from data: Data, ofType typeName: String) throws {
        let isTypeEmail = UTTypeConformsTo(typeName as CFString, Names.internationalEmailMessageUTI as CFString)
        guard isTypeEmail else { throw CocoaError(.fileReadUnknown) }

        // Parse the incoming data.
        let operationalMessage = InternetMessageReadingOperation(data: data)
        operationalMessage.start()
        assert(operationalMessage.isFinished)
        guard !operationalMessage.isCancelled else { throw CocoaError(.userCancelled) }

        // Create a document message object from the operation message object.
        var backgroundMessage: RawMessage!
        var backgroundError: Error?
        let backgroundContext = self.container.newBackgroundContext()
        backgroundContext.performAndWait {
            backgroundMessage = RawMessage(context: backgroundContext)
            for field in operationalMessage.header {
                let fieldObject = RawHeaderField(context: backgroundContext)
                fieldObject.name = field.name
                fieldObject.body = field.body
                fieldObject.message = backgroundMessage
            }
            backgroundMessage.body = operationalMessage.body

            do {
                try backgroundContext.save()
            } catch {
                backgroundError = error
            }
        }
        guard backgroundError == nil else { throw backgroundError! }

        // Replace the current message with a copy of the new one.
        let mainContext = self.container.viewContext
        mainContext.performAndWait {
            self.undoManager?.disableUndoRegistration()
            defer { self.undoManager?.enableUndoRegistration() }

            let oldMessage = self.message
            self.message = mainContext.object(with: backgroundMessage.objectID) as! RawMessage
            mainContext.delete(oldMessage!)
            try! mainContext.save()  // Can't really recover; the new message is already in.
        }
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSSaveOperationType) -> Bool {
        let isTypeEmail = UTTypeConformsTo(typeName as CFString, Names.internationalEmailMessageUTI as CFString)
        if isTypeEmail {
            return true
        } else {
            return super.canAsynchronouslyWrite(to: url, ofType: typeName, for: saveOperation)
        }
    }

    override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
        let isTypeEmail = UTTypeConformsTo(typeName as CFString, Names.internationalEmailMessageUTI as CFString)
        if isTypeEmail {
            return true
        } else {
            return super.canConcurrentlyReadDocuments(ofType: typeName)
        }
    }

    override func save(to url: URL, ofType typeName: String, for saveOperation: NSSaveOperationType, completionHandler: @escaping (Error?) -> Void) {
        // Save the message data to the store so any background contexts can read the data later.
        let mainContext = self.container.viewContext
        var gotError = false
        mainContext.performAndWait {
            do {
                try mainContext.save()
            } catch {
                completionHandler(error)
                gotError = true
            }
        }
        guard !gotError else { return }

        // Do the usual code, possibly even use a background thread.
        super.save(to: url, ofType: typeName, for: saveOperation, completionHandler: completionHandler)
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
