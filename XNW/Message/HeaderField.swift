//
//  HeaderField.swift
//  XNW
//
//  Created by Daryle Walker on 5/1/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import Foundation


/// Represents a field (name and body) from the header of an Internet Message (i.e. RFC 822 and its updates).
public protocol HeaderField {

    /// The name of the field.  Must pass `problemsValidatingName(_:)` with no errors.  To pass includes being non-empty and having all characters part of `CharacterSets.fieldName`.
    var name: String { get }
    /// The body of the field.  Must pass `problemsValidatingBody(_:)` with no errors.  To pass includes having no NUL/control/CR/LF characters.
    var body: String { get }

    /**
        Determines the problem(s) preventing the given string being used as an instance's `name` property.  Overrides must not permit strings that the default implementation would forbid.  For a conforming type representing a subset of header fields, this method could check if the given `name` can be the title of a handled field.

        - parameter name: The candidate to parse.

        - returns: The various errors a potential throwing initializer would emit if `name` was passed as a field title.  Empty if there are no errors.
     */
    static func problemsValidatingName(name: String) -> [ErrorType]
    /**
        Determines the problem(s) preventing the given string being used as an instance's `body` property.  Overrides must not permit strings that the default implementation would forbid.  For a conforming type representing a subset of header fields, this method could parse the `body` to check if it can represent the data in a handled field.

        - parameter body: The candidate to parse.

        - returns: The various errors a potential throwing initializer would emit if `body` was passed as a field value.  Empty if there are no errors.
     */
    static func problemsValidatingBody(body: String) -> [ErrorType]

    /// A copy of `postface` with the text split where any needed line breaks should go.  Since `bodyFragments.description` equals `postface` and `postface` is either `body` or one space longer than `body`, then either one of {`body`, `bodyFragments`} should be defined in terms of the other, or both are synthesized from a third property (or set of).  If the body has structure, then the fragements should be a tree for each elemnt instead of a flat list.
    var bodyFragments: HeaderFieldBodyFragment { get }

}

// MARK: Default Implementations

public extension HeaderField {

    /// Default implementation of header field name validation function.
    static func problemsValidatingName(name: String) -> [ErrorType] {
        var result: [ErrorType] = []
        if name.utf8.count < HeaderFieldConstants.minimumNameOctetLength {
            result.append(MessageError.HeaderFieldNameTooShort)
        }
        if name.rangeOfCharacterFromSet(CharacterSets.fieldName.invertedSet) != nil {
            result.append(MessageError.HeaderFieldNameInvalidCharacters)
        }
        return result
    }
    /// Default implementation of header field body validation function.
    static func problemsValidatingBody(body: String) -> [ErrorType] {
        var result: [ErrorType] = []
        if body.rangeOfCharacterFromSet(CharacterSets.fieldBodyBannedStrict) != nil {
            result.append(MessageError.HeaderFieldBodyInvalidCharacters)
        }
        return result
    }

    /// Default implementation of line-breaker-marked `postface`.
    var bodyFragments: HeaderFieldBodyFragment {
        let extendedBody = postface
        var fragments: [HeaderFieldBodyFragment] = []
        var index = extendedBody.startIndex
        let end = extendedBody.endIndex
        while index < end {
            // Find the bounds of the block of non-whitespace following the current (whitespace) character.
            if let blockStart = extendedBody.rangeOfCharacterFromSet(CharacterSets.whitespace.invertedSet, options: [], range: index..<end)?.startIndex {
                assert(index < blockStart)
                let blockEnd = extendedBody.rangeOfCharacterFromSet(CharacterSets.whitespace, options: [], range: blockStart..<end)?.startIndex ?? end
                fragments.append(HeaderFieldBodyFragment(single: extendedBody[index..<blockEnd])!)
                index = blockEnd
                continue
            }

            // Got a trailing whitespace block.
            let trailingSpaces = extendedBody.substringFromIndex(index)
            let lastFragment = fragments.popLast()
            assert(lastFragment == nil || lastFragment!.fragments.count == 1)
            var lastFragmentString = lastFragment?.fragments.last
            if lastFragmentString != nil {
                lastFragmentString!.appendContentsOf(trailingSpaces)
            } else {
                lastFragmentString = trailingSpaces
            }
            fragments.append(HeaderFieldBodyFragment(single: lastFragmentString!)!)
            index = end
        }
        return HeaderFieldBodyFragment(group: fragments)
    }

}

// MARK: Serialization

public extension HeaderField {

    /// The leading half of the field's line of text.
    public var preface: String {
        return name + ":"
    }
    /// The trailing half of the field's line of text.
    public var postface: String {
        if let leader = body.utf16.first where !CharacterSets.whitespace.characterIsMember(leader) {
            return " " + body
        }
        return body
    }
    /// A copy of `postface` with the line breaks needed for `wrappedDescription`.
    public var wrappedPostface: String {
        let baseWrap = wrappedDescription
        let prefaceIndex = baseWrap.rangeOfString(preface)!
        assert(prefaceIndex.startIndex == baseWrap.startIndex)
        return baseWrap.substringFromIndex(prefaceIndex.endIndex)
    }
    
    /// The field converted to a single line of text
    public var fieldDescription: String {
        return preface + postface
    }
    /// The field converted to a set of text lines, better suited for printing/display.  It's `fieldDescription` wrapped via new line breaks every 78 characters (or so).  Runs of non-whitespace text won't be broken.
    public var wrappedDescription: String {
        return bodyFragments.descriptionAppendedTo(preface, softCutoff: InternetMessageConstants.preferredMaximumLineCharacterLength) + LineBreaks.internalString
    }

}

// MARK: Integrity Checks

public extension HeaderField {

    /// Whether or not any indivisible portion of the field is too long for the IMF line length limit (998 octets between line breaks).  As long as each section is short enough, the entire field can be as long as desired (due to wrapping).
    public var tooLong: Bool {
        let title = preface + (bodyFragments.allWhitespaceStart ?? "")
        return max(title.utf8.count, bodyFragments.maximumFragmentLength) > InternetMessageConstants.maximumLineOctetLength
    }
    /// Whether or not the field, both name and body, meets validation invariants.  This should be always `true` after the instance finishes all of its initialization stages (an initializer and any post-init setup, like NIBs), and stay true if there are mutating methods upon the name or body.
    public var meetsFieldInvariants: Bool {
        return Self.problemsValidatingName(name).isEmpty && Self.problemsValidatingBody(body).isEmpty
    }

}

// MARK: - Header Field with Validating Initializer

/// A header field extension that takes in name and body values upon initialization and immediately checks them.
public protocol ValidatingInitializerHeaderField: HeaderField {

    /**
        Possibly create an instance from the given properties.
     
        - parameter name: The header field name.
        - parameter body: The header field body.
        - throws: If either `name` or `body` fails the basic requirements or fails the particular requirments of the represented sub-type.
        - postcondition: `self.name == name` and `self.body` is a sanitized version of `body`.
     */
    init(name: String, body: String) throws

}

// MARK: - Constants for Header Field Limits

public enum HeaderFieldConstants {

    /// The minimum length of a header field name, in octets.  (Since the name must be pure ASCII, it's also the character length.)
    public static let minimumNameOctetLength = 1
    /// The maximum length of a header field name, in octets.  It's derived from SMTP 1000 octet limit per line, minus 2 for the terminating CRLF, and another one for the colon after the name.
    public static let maximumNameOctetLength = InternetMessageConstants.maximumLineOctetLength - 1
    /// The maximum length of a non-whitespace string in a header field body.  Uses the same reasoning as `maximumNameOctetLength`, except the trailing colon is replaced by a leading whitespace character.  (There is no minimum length for a string.  There is no overall maximum length for the body, due to whitespace folding.)
    public static let maximumBodyOctetLength = maximumNameOctetLength

}
