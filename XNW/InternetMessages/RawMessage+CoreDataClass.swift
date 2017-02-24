//
//  RawMessage+CoreDataClass.swift
//  XNW
//
//  Created by Daryle Walker on 2/10/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation
import CoreData


// This line and the internals of the following block were added.
public class RawMessage: NSManagedObject {

    /// The default policy of whether the body and any field bodies directly accept post-ASCII Unicode characters.
    public static let acceptUnicodeDefault = true

    /// Whether the body and any field bodies should accept post-ASCII Unicode characters.
    public var acceptUnicode = RawMessage.acceptUnicodeDefault

}
