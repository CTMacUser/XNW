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

    // Check if the current URL-open panel is really for an import.
    fileprivate var pendingImports = 0

    // MARK: Overrides

    override func runModalOpenPanel(_ openPanel: NSOpenPanel, forTypes types: [String]?) -> Int {
        if pendingImports > 0 {
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

        This method calls `duplicateDocument(withContentsOf:copying:displayName:)` to copy the data to new `NSDocument` objects.
     */
    @IBAction func newDocumentFrom(_ sender: Any?) {
        self.pendingImports += 1
        self.beginOpenPanel { possibleFiles in
            self.pendingImports -= 1
            guard let files = possibleFiles else { return }

            for file in files {
                do {
                    let fileResources = try file.resourceValues(forKeys: [.localizedNameKey])
                    try self.duplicateDocument(withContentsOf: file, copying: true, displayName: fileResources.localizedName)
                } catch {
                    self.presentError(error)  // Ignore any recovery
                }
            }
        }
    }

}
