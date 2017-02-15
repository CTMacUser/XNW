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



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        // This won't be set in time if in `applicationDidFinishLaunching`.
        ValueTransformer.setValueTransformer(OrderedSetArrayValueTransformer(), forName: OrderedSetArrayValueTransformer.name)
    }


}

