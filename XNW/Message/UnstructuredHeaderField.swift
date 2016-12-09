//
//  UnstructuredHeaderField.swift
//  XNW
//
//  Created by Daryle Walker on 5/20/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import Foundation


/// A header field with no expected internal structure to its body.
public struct UnstructuredHeaderField: ValidatingInitializerHeaderField {

    /// The name of the field.
    public let name: String
    /// The body of the field.
    public var body: String {
        return String(bodyFragments.description.characters.dropFirst(needsInitialSpace ? 1 : 0))
    }
    /// Whether or not the `body` started with a whitespace character (or if one needs to be added during `description`).
    private let needsInitialSpace: Bool

    /// Reads the given `name` and `body`.  Sets them if they validate, throws if at least one doesn't.
    public init(name: String, body: String) throws {
        // Handle name.
        let nameProblems = self.dynamicType.problemsValidatingName(name)
        guard nameProblems.isEmpty else {
            throw nameProblems.first!
        }
        self.name = name

        // Instead of rejecting bodies with bad characters, just filter out those characters.
        var sanitizedBody = body.componentsSeparatedByCharactersInSet(CharacterSets.fieldBodyBannedStrict).joinWithSeparator("")
        assert(UnstructuredHeaderField.problemsValidatingBody(sanitizedBody).isEmpty)
        needsInitialSpace = !sanitizedBody.isEmpty && !CharacterSets.whitespace.characterIsMember(sanitizedBody.utf16.first!)
        if needsInitialSpace {
            sanitizedBody.insert(" ", atIndex: sanitizedBody.startIndex)
        }

        // Reuse the fragment-parsing code from the protocol's default implementation.
        struct SecretHeaderField: HeaderField {
            var name: String
            var body: String
        }

        let secret = SecretHeaderField(name: name, body: sanitizedBody)
        bodyFragments = secret.bodyFragments
    }

    /// The `body` of the field broken where line breaks can be inserted.
    public let bodyFragments: HeaderFieldBodyFragment

}
