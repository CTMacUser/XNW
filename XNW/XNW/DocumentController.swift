//
//  DocumentController.swift
//  XNW
//
//  Created by Daryle Walker on 3/6/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Cocoa
import Foundation


/// A document controller that can handle imports.
class DocumentController: NSDocumentController {

    // MARK: Properties

    // Check if the current URL open is really an import; recording files needing import.
    fileprivate var imports = [URL]()
    // Check if the current URL-open panel is really for an import.
    fileprivate var tryingImport = false

    // MARK: Overrides

    override func addDocument(_ document: NSDocument) {
        // Don't record files temporarily opened for import.
        if let file = document.fileURL, let importIndex = imports.index(of: file) {
            imports.remove(at: importIndex)
        } else {
            super.addDocument(document)
        }
    }

    override func runModalOpenPanel(_ openPanel: NSOpenPanel, forTypes types: [String]?) -> Int {
        if tryingImport {
            openPanel.title = NSLocalizedString("Import", comment: "Title of Import Open-Panel")
            openPanel.prompt = NSLocalizedString("Import", comment: "Prompt on OK button of Import Open-Panel")
        }
        return super.runModalOpenPanel(openPanel, forTypes: types)
    }

}

// MARK: Actions

extension DocumentController {

    /**
        An action method called by the Import command, it runs the modal Open panel and, based on the selected filenames, creates one or more `NSDocument` objects from the contents of the files, but stripping the file identities.

        The method adds the newly created objects to the list of `NSDocument` objects managed by the document controller.  This method calls `openDocument(withContentsOf:display:completionHandler:)`, which creates the first round of `NSDocument` objects.  The documents are anonymized by duplication, and closing any of the first set of documents that weren't already open.
     */
    @IBAction func newDocumentFrom(_ sender: Any?) {
        self.tryingImport = true
        self.beginOpenPanel { possibleFiles in
            self.tryingImport = false
            guard let files = possibleFiles else { return }

            for file in files {
                self.imports.append(file)
                self.openDocument(withContentsOf: file, display: false) { possibleDocument, alreadyOpen, possibleError in
                    if let error = possibleError {
                        self.presentError(error)  // Ignore any recovery
                    }
                    if alreadyOpen {
                        self.imports.remove(at: self.imports.index(of: file)!)
                    }
                    if let document = possibleDocument {
                        do {
                            try self.duplicateDocument(withContentsOf: file, copying: true, displayName: document.displayName)
                        } catch {
                            self.presentError(error) // Ignore any recovery
                        }
                        if !alreadyOpen {
                            document.close()
                        }
                    }
                }
            }
        }
    }

}
