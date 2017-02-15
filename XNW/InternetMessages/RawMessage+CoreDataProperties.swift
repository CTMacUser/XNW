//
//  RawMessage+CoreDataProperties.swift
//  XNW
//
//  Created by Daryle Walker on 2/10/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation
import CoreData


extension RawMessage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RawMessage> {
        return NSFetchRequest<RawMessage>(entityName: "Message");
    }

    @NSManaged public var body: String?
    @NSManaged public var header: NSOrderedSet  // Originally generated as "NSOrderedSet?"

}

// MARK: Generated accessors for header
extension RawMessage {

    @objc(insertObject:inHeaderAtIndex:)
    @NSManaged public func insertIntoHeader(_ value: RawHeaderField, at idx: Int)

    @objc(removeObjectFromHeaderAtIndex:)
    @NSManaged public func removeFromHeader(at idx: Int)

    @objc(insertHeader:atIndexes:)
    @NSManaged public func insertIntoHeader(_ values: [RawHeaderField], at indexes: NSIndexSet)

    @objc(removeHeaderAtIndexes:)
    @NSManaged public func removeFromHeader(at indexes: NSIndexSet)

    @objc(replaceObjectInHeaderAtIndex:withObject:)
    @NSManaged public func replaceHeader(at idx: Int, with value: RawHeaderField)

    @objc(replaceHeaderAtIndexes:withHeader:)
    @NSManaged public func replaceHeader(at indexes: NSIndexSet, with values: [RawHeaderField])

    @objc(addHeaderObject:)
    @NSManaged public func addToHeader(_ value: RawHeaderField)

    @objc(removeHeaderObject:)
    @NSManaged public func removeFromHeader(_ value: RawHeaderField)

    @objc(addHeader:)
    @NSManaged public func addToHeader(_ values: NSOrderedSet)

    @objc(removeHeader:)
    @NSManaged public func removeFromHeader(_ values: NSOrderedSet)

}
