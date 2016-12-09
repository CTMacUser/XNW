//
//  HeaderFieldBodyFragment.swift
//  XNW
//
//  Created by Daryle Walker on 5/22/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import Foundation


/// Organizes parts of a header field body to facilitate line-wrapping.
public enum HeaderFieldBodyFragment: CustomStringConvertible {

    case single(String)
    case group([HeaderFieldBodyFragment])

    /// Initialize from a group of sub-fragments.
    public init(group: [HeaderFieldBodyFragment]) {
        self = .group(group)
    }
    /// Initialize from a list of sub-fragments.
    public init(fragments: HeaderFieldBodyFragment...) {
        self = .group(fragments)
    }
    /// Default-initialize to an empty group.
    public init() {
        self.init(group: [])
    }
    /// Initialize from a core unit: a string that starts with whitespace.
    public init?(single: String) {
        guard let firstSingle = single.utf16.first where CharacterSets.whitespace.characterIsMember(firstSingle) else {
            return nil
        }

        self = .single(single)
    }

    /// A (flattened) list of the core strings.
    public var fragments: [String] {
        switch self {
        case let .single(core):
            return [core]
        case let .group(subFragments):
            return subFragments.flatMap { $0.fragments }
        }
    }

    public var description: String {
        return fragments.joinWithSeparator("")
    }

    /**
        Returns a copy of the description that's wrapped (i.e. a line break gets inserted) after a span of characters.

        - parameter linePrefix: A constant string prepened to the description.

        - parameter softCutoff: Non-negative integer; If the last line in the description so far will exceed this length if the next segment is added, and if the  segment isn't just a nonzero length of whitespace, put in a break between the line and segment instead.

        - returns: The wrapped description.
     */
    public func descriptionAppendedTo(linePrefix: String, softCutoff: Int) -> String {
        precondition(softCutoff >= 0)

        let partialLineStart = linePrefix.rangeOfString(LineBreaks.internalString, options: .BackwardsSearch)?.endIndex ?? linePrefix.startIndex
        let baseDescription = description
        if baseDescription.isEmpty || baseDescription.rangeOfCharacterFromSet(CharacterSets.whitespace.invertedSet) == nil || baseDescription.characters.count + partialLineStart.distanceTo(linePrefix.endIndex) <= softCutoff {
            return linePrefix + baseDescription
        }
        switch self {
        case let .single(core):
            return linePrefix + LineBreaks.internalString + core
        case let .group(subFragments):
            var result = linePrefix
            for f in subFragments {
                result = f.descriptionAppendedTo(result, softCutoff: softCutoff)
            }
            return result
        }
    }

    /// If this instance's first sub-fragment is all whitespace, a copy of those spaces.
    public var allWhitespaceStart: String? {
        switch self {
        case let .single(core):
            return core.rangeOfCharacterFromSet(CharacterSets.whitespace.invertedSet) == nil ? core : nil
        case let .group(fragments):
            return fragments.first?.allWhitespaceStart
        }
    }

    /// Length of the longest sub-fragment, in UTF-8 code points.
    public var maximumFragmentLength: Int {
        return fragments.map { $0.utf8.count }.maxElement() ?? 0
    }

}
