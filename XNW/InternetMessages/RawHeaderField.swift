//
//  RawHeaderField.swift
//  XNW
//
//  Created by Daryle Walker on 2/10/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation


// The definition of the class is in "RawHeaderField+CoreDataClass.swfit" and its Core Data properties in "RawHeaderField+CoreDataProperties".
extension RawHeaderField {

    // MARK: Validation

    /// KVC validation routine for the `name` property.
    public func validateName(value: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        guard let value = value.pointee else { return }

        let name = value as! String
        if let error = RawHeaderField.invalidationsOn(name: name, flagTooLongForTransmission: true).first {
            throw error
        }
    }

    /// KVC validation routine for the `body` property.
    public func validateBody(value: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        guard let value = value.pointee else { return }

        let body = value as! String
        if let error = RawHeaderField.invalidationsOn(body: body, flagHasInternationalCharacters: !self.acceptUnicodeInBody).first {
            throw error
        }
    }

    // Validate the primary data: name and body.
    private func validateNameAndBody() throws {
        if let error = self.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: !self.acceptUnicodeInBody).first {
            throw error
        }
    }

    // MARK: Overrides

    public override func validateForInsert() throws {
        try super.validateForInsert()
        try self.validateNameAndBody()
    }

    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try self.validateNameAndBody()
    }

}
