//
//  AppDelegate.swift
//  XNW
//
//  Created by Daryle Walker on 1/1/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Load the initial preferences
        UserDefaults.standard.register(defaults: Defaults.appDefaults)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: NSMenuValidation (informal)

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let action = menuItem.action else { return super.validateMenuItem(menuItem) }

        switch action {
        case #selector(removeHeaderField(_:)):
            // There's no message header active to do any work; this validation just changes the title back to the default.
            menuItem.title = NSLocalizedString("Remove Header Field", comment: "Title of the 'Remove Header Field' menu item when no qualifying window is open.")
            return false

        default:
            return super.validateMenuItem(menuItem)
        }
    }

}

// MARK: Actions

extension AppDelegate {

    @IBAction func removeHeaderField(_ sender: Any) {
        // Nothing; the real version is in `MessageWindowController`.
    }

}
