//
//  RawMessage.swift
//  XNW
//
//  Created by Daryle Walker on 2/19/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation


// The definition of the class is in "RawMessage+CoreDataClass.swfit" and its Core Data properties in "RawMessage+CoreDataProperties".
extension RawMessage {

    // MARK: Array-oriented KVC methods for `header`

    // These methods/property make a pseudo-property called `headerAsArray`.

    var headerAsArrayCount: Int {
        @objc(countOfHeaderAsArray)
        get {
            return self.header.count
        }
    }

    @objc(objectInHeaderAsArray:)
    func objectInHeaderAsArrayAtIndex(index: Int) -> Any {
        return self.header.object(at: index)
    }

    @objc(headerAsArrayAtIndexes:)
    func headerAsArrayAtIndexes(indexes: IndexSet) -> [Any] {
        return self.header.objects(at: indexes)
    }

    @objc(insertObject: inHeaderAsArrayAtIndex:)
    func insertIntoHeaderAsArray(_ value: RawHeaderField, at index: Int) {
        self.insertIntoHeader(value, at: index)
    }

    @objc(insertHeaderAsArray: atIndexes:)
    func insertIntoHeaderAsArray(_ values: [RawHeaderField], at indexes: IndexSet) {
        self.insertIntoHeader(values, at: indexes as NSIndexSet)
    }

    @objc(removeObjectFromHeaderAsArrayAtIndex:)
    func removeFromHeaderAsArray(at index: Int) {
        self.removeFromHeader(at: index)
    }

    @objc(removeHeaderAsArrayAtIndexes:)
    func removeFromHeaderAsArray(at indexes: IndexSet) {
        self.removeFromHeader(at: indexes as NSIndexSet)
    }

    @objc(replaceObjectInHeaderAsArrayAtIndex: withObject:)
    func replaceHeaderAsArray(at index: Int, with value: RawHeaderField) {
        self.replaceHeader(at: index, with: value)
    }

    @objc(replaceHeaderAsArrayAtIndexes: withHeaderAsArray:)
    func replaceHeaderAsArray(at indexes: IndexSet, with values: [RawHeaderField]) {
        self.replaceHeader(at: indexes as NSIndexSet, with: values)
    }

    /// Note that the original attribute affects this one.
    class func keyPathsForValuesAffectingHeaderAsArray() -> Set<String> {
        return [#keyPath(RawMessage.header)]
    }

}
