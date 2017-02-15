//
//  InternetMessageHeaderField.swift
//  XNW
//
//  Created by Daryle Walker on 2/7/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation


/// Represents a header field defined in the Internet Message Format, as described in RFC 5322.  The internationalized extensions are described in RFC 6532.
public protocol InternetMessageHeaderField {
    /// The name of a header field.  Must satisfy `invalidationsOn(name: flagTooLongForTransmission: )` with your given options.
    var name: String { get }
    /// The body of a header field.  Must be in the unfolded state (i.e. no CR nor LF contained).  Must satisfy `invalidationsOn(body: flagHasInternationalCharacters: )` with your given options.
    var body: String { get }

    /**
        The full text of the header field: the name, followed by a colon, then the body.  This is without line folding.
        By default, a standard space needs to be between the separating colon and body to satisfy transmission over NNTP, per Netnews article RFC 5536 (which also specifies that the body must have at least on non-blank character).
        There's generally no need to override the standard definition given in a later extension, unless the extra space after the colon is *really* not wanted.

        - Invariant: `line.hasPrefix(name + ":") && line.hasSuffix(body)`
        - Invariant: `1...2 ~= line.characters.count - name.characters.count - body.characters.count` (The excess is the colon and possibly a standard space.)
     */
    var line: String { get }
    /**
        The full text of the header field, with folding applied.
        Instead of a single string with line-breaking character sequences added, the segments are provided as separate strings (without any other changes).
        Although the standard definition (given in a later extension) will do, fields with internal sections should provide an override that splits along section boundaries.

        - Invariant: `wrappedLineSegments.joined() == line`
        - Invariant: For each element:
            - Cannot be empty.
            - For display purposes, the element *should* not exceed 78 characters in length.
            - If compatibility for transmitting over NNTP/SMTP/etc. is desired, the UTF-8 expansion of its NFC normalization form **must** not exceed 998 octets.
        - Invariant: For each non-first element (if any):
            - The first character is either a standard space or horizontal tab.
            - At least one contained character is neither of those.
     */
    var wrappedLineSegments: [String] { get }
}

/// Represents a header field that can be mutated.
public protocol InternetMessageHeaderMutableField: InternetMessageHeaderField {

    /// The name of a header field.  Shouldn't be set to a value that would violate the get-mode invariants.
    var name: String { get set }
    /// The body of a header field.  Shouldn't be set to a value that would violate the get-mode invariants.
    var body: String { get set }

}

// MARK: - Validation

extension InternetMessageHeaderField {

    /**
        Check the potential name string for problems.  The given string is always checked if it's not empty and if all its contained characters are in the proper range (`"!"` through `"~"`, inclusive, excluding `":"`).

        - Parameter name: The name string to analyze.
        - Parameter flagTooLongForTransmission: Check if `name` isn't too long for the field to be safely transmitted over SMTP/NNTP/etc. and add that error flag if the check fails.

        - Returns: All the potential errors found.  Empty if `name` pass all tests.
     */
    public static func invalidationsOn(name: String, flagTooLongForTransmission: Bool) -> Set<InternetMessageError> {
        var errors = Set<InternetMessageError>()
        if name.isEmpty {
            errors.insert(.headerFieldNameIsTooShort)
        }
        if name.rangeOfCharacter(from: InternetMessageConstants.ftext.inverted) != nil {
            errors.insert(.headerFieldNameHasInvalidCharacters)
        }
        if flagTooLongForTransmission && name.precomposedStringWithCanonicalMapping.utf8.count >= InternetMessageConstants.maximumAllowedOctetsPerLine {
            errors.insert(.headerFieldNameIsTooLongForTransmission)
        }
        return errors
    }

    /**
        Check the potential body string for problems.  The given string is always checked if all its contained characters are outside the banned ASCII range (all the control characters except horizontal-tab).

        - Parameter body: The body string to analyze.
        - Parameter flagHasInternationalCharacters: Check if `body` doesn't contain any Unicode characters outside the ASCII range (Encoded post-ASCII characters are OK.) and add that error flag if the check fails.

        - Returns: All the potential errors found.  Empty if `body` pass all tests.
     */
    public static func invalidationsOn(body: String, flagHasInternationalCharacters: Bool) -> Set<InternetMessageError> {
        var errors = Set<InternetMessageError>()
        if body.rangeOfCharacter(from: InternetMessageConstants.bannedFromUnstructured) != nil {
            errors.insert(.headerFieldBodyHasInvalidAsciiCharacters)
        }
        if flagHasInternationalCharacters && body.rangeOfCharacter(from: InternetMessageConstants.postAscii) != nil {
            errors.insert(.headerFieldBodyHasInvalidUnicodeCharacters)
        }
        return errors
    }

    // The obsolete header field body syntax allowed ALL characters!  (Lines were broken at exact CRLF matches.)

    // The body can't be checked directly for transport line-length violations.  Only when checking the wrapped segments, which also considers the name and separating colon.

    /**
        Report on all the problems with the value, both property-specific and composite problems.

        - Parameter flagTooLongForTransmission: Check if the `name` isn't too long for the field to be safely transmitted over SMTP/NNTP/etc. and add that error flag if the check fails.  Also check if the combined `name` and `body` (see `line`) doesn't have segments too long after wrapping.
        - Parameter flagHasInternationalCharacters: Check if the `body` doesn't directly have Unicode characters outside the ASCII range (Post-ASCII characters encoded in the ASCII range are OK.) and add that error flag if the check fails.

        - Returns: All the errors found.  Empty if the field passes all the listed tests.
     */
    public func invalidations(flagTooLongForTransmission: Bool, flagHasInternationalCharacters: Bool) -> Set<InternetMessageError> {
        var errors = Self.invalidationsOn(name: self.name, flagTooLongForTransmission: flagTooLongForTransmission)
        errors.formUnion(Self.invalidationsOn(body: self.body, flagHasInternationalCharacters: flagHasInternationalCharacters))
        if flagTooLongForTransmission && self.wrappedLineSegments.map({ $0.precomposedStringWithCanonicalMapping.utf8.count }).reduce(.min, max) > InternetMessageConstants.maximumAllowedOctetsPerLine {
            errors.insert(.headerFieldCouldNotBeWrappedForTransmission)
        }
        return errors
    }

}

// MARK: Line Generation

extension InternetMessageHeaderField {

    // A basic header line from the name, body, and separating colon.  The extra space for net-news is present.
    public var line: String {
        return "\(self.name):\((self.body.characters.first ?? " ") == " " ? self.body : " \(self.body)")"
    }

    // Break `line` to spans of blanks and non-blanks and pair one of each.
    public var wrappedLineSegments: [String] {
        // Make segments, where each string is either all blanks or all non-blanks, and the two kinds alternate.
        let wsp = InternetMessageConstants.wsp
        var (result, checkMatch) = self.line.consecutiveComponents(untilChangedOn: wsp)
        assert(!result.isEmpty)
        assert(checkMatch! == false)  // The first segment is always all non-blanks.

        // Since a returned segment can't be all blanks, a trailing blank string has to be attached to the last non-blank string.
        if result.count % 2 == 0 {  // Count can't be zero, due to preconditions.
            result[result.count - 2].append(result.last!)
            result.removeLast()
        }

        // Now we should have a segment of the field name and separating colon, with each following pair being a segment of all blanks then a segment of all non-blanks (possibly except the last segment, which could have trailing blanks).  Each pair is fused into the same segment and then possibly attached to the previous one.  If both the fused and previous segments could end up too long, then some blanks are transferred to relieve pressure.

        var seedSegmentIndex = result.startIndex
        primary: while seedSegmentIndex < result.endIndex - 1 {
            let lengthLimit = InternetMessageConstants.maximumPreferredCharactersPerLine
            let indexOffset = seedSegmentIndex - result.startIndex
            attach: while result[seedSegmentIndex].characters.count < lengthLimit {
                guard seedSegmentIndex < result.endIndex - 2 else { break primary }

                let nextBlankSegmentIndex = seedSegmentIndex + 1
                let nextNonBlankSegmentIndex = nextBlankSegmentIndex + 1
                assert(wsp.contains(result[nextBlankSegmentIndex].unicodeScalars.first!))
                assert(wsp.inverted.contains(result[nextNonBlankSegmentIndex].unicodeScalars.first!))

                var seedSegmentCount = result[seedSegmentIndex].characters.count
                var blankCount = result[nextBlankSegmentIndex].characters.count
                let nonBlankCount = result[nextNonBlankSegmentIndex].characters.count
                switch seedSegmentCount + blankCount + nonBlankCount {
                case let shortEnough where shortEnough <= lengthLimit:
                    result[seedSegmentIndex].append(result[nextBlankSegmentIndex] + result[nextNonBlankSegmentIndex])
                    result.removeSubrange(nextBlankSegmentIndex...nextNonBlankSegmentIndex)
                    seedSegmentIndex = result.startIndex + indexOffset  // Undo invalidation from `removeSubrange`
                case let tooLong where tooLong > lengthLimit && seedSegmentCount < lengthLimit && (blankCount + nonBlankCount) > lengthLimit:
                    while seedSegmentCount < lengthLimit && blankCount > 1 {
                        result[seedSegmentIndex].append(result[nextBlankSegmentIndex].characters.removeFirst())
                        seedSegmentCount += 1
                        blankCount -= 1
                    }
                    fallthrough
                default:
                    break attach
                }
            }

            result[seedSegmentIndex + 1].append(result[seedSegmentIndex + 2])
            result.remove(at: seedSegmentIndex + 2)
            seedSegmentIndex = result.startIndex + indexOffset + 1  // Undo invalidation from `remove` and increment
        }

        return result
    }

}
