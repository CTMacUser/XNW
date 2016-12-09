//
//  MessageModel.swift
//  XNW
//
//  Created by Daryle Walker on 6/3/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import Foundation
import Message


// MARK: Header Field

/// A field in the header section of a message.
class RegularHeaderField: NSObject, HeaderField {

    /// The name of the field.
    dynamic var name: String
    /// The body of the field.
    dynamic var body: String

    /// Initialize a header field.
    init(name: String, body: String) throws {
        if let firstError = (self.dynamicType.problemsValidatingName(name) + self.dynamicType.problemsValidatingBody(body)).first {
            throw firstError
        }
        self.name = name
        self.body = body
    }

}

// MARK: Key-Value Coding

extension RegularHeaderField {

    /// Validate new names.
    func validateName(ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        guard let newName = ioValue.memory as? NSString else {
            throw NSCocoaError.KeyValueValidationError
        }

        if let firstError = self.dynamicType.problemsValidatingName(newName as String).first {
            throw firstError
        }
        // Else: do nothing, to pass ioValue through.
    }

    /// Validate new bodies.
    func validateBody(ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        guard let newBody = ioValue.memory as? NSString else {
            throw NSCocoaError.KeyValueValidationError
        }
        
        if let firstError = self.dynamicType.problemsValidatingBody(newBody as String).first {
            throw firstError
        }
        // Else: do nothing, to pass ioValue through.
    }

}

// MARK: - Internet Message

/// A message in the Internet Message Format.
class RegularInternetMessage: NSObject, InternetMessage {

    /// There is no extra data to pass during initialization.
    typealias Configuration = Void

    /// The header of the message.
    dynamic var header: [RegularHeaderField]
    /// The (optional) body of the message.
    dynamic var body: String?

    /// Initialize to an empty header and absent body.
    required init(configuration: Configuration) {
        header = []
    }

    /// Convert a parsed header field for storage.
    func transformField(sample: ValidatingInitializerHeaderField) -> RegularHeaderField {
        return try! RegularHeaderField(name: sample.name, body: sample.body)
    }

}
