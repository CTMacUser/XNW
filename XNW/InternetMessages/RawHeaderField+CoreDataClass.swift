//
//  RawHeaderField+CoreDataClass.swift
//  XNW
//
//  Created by Daryle Walker on 2/10/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation
import CoreData


// This line and the internals of the following block were added.
public class RawHeaderField: NSManagedObject {

    /// The default policy of whether the field body directly accepts post-ASCII Unicode characters.
    public static let acceptUnicodeInBodyDefault = true

    /// Whether the field body should accept post-ASCII Unicode characters.
    public var acceptUnicodeInBody = RawHeaderField.acceptUnicodeInBodyDefault

}
