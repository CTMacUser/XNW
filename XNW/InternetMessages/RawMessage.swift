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

    // MARK: Validation

    /// KVC validation routine for the `header` property.
    public func validateHeader(value: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        guard let value = value.pointee else { return }

        let header = value as! NSOrderedSet
        if let error = RawMessage.invalidationsOn(header: header, flagTooLongForTransmission: true, flagHasInternationalCharacters: !self.acceptUnicode).first {
            throw error
        }
    }

    /// KVC validation routine for the `body` property.
    public func validateBody(value: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        guard let value = value.pointee else { return }
        guard let body = value as? String else { return }

        if let error = RawMessage.invalidationsOn(body: body, flagTooLongForTransmission: true, flagHasInternationalCharacters: !self.acceptUnicode).first {
            throw error
        }
    }

    // Validate the primary data: header and body.
    private func validateHeaderAndBody() throws {
        if let error = self.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: !self.acceptUnicode).first {
            throw error
        }
    }

    // MARK: Overrides

    public override func validateForInsert() throws {
        try super.validateForInsert()
        try self.validateHeaderAndBody()
    }

    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try self.validateHeaderAndBody()
    }

}
