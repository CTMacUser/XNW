//
//  String+Additions.swift
//  XNW
//
//  Created by Daryle Walker on 2/13/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation


extension String {

    /**
        Find alternating substrings that are runs of characters that either match or don't match a criteria.

        - Parameter untilChangedOn: A character set that is compared against to find matching (and non-matching) characters.
        - Parameter options: Tweaks to how the character comparison is done.

        - Returns: Two pieces of data
            - First, the substrings, which comprise the entire string, that alternate between matching the set and not matching.
            - Second, whether the first substring is a match or an anti-match.  `Nil` if the string is empty.
     */
    func consecutiveComponents(untilChangedOn: CharacterSet, options mask: String.CompareOptions = []) -> ([String], firstOneMatches: Bool?) {
        guard !self.isEmpty else { return ([], nil) }

        let antiUntil = untilChangedOn.inverted
        guard let mismatchIndex = self.rangeOfCharacter(from: antiUntil, options: mask)?.lowerBound else {
            return ([self], true)
        }
        guard let matchIndex = self.rangeOfCharacter(from: untilChangedOn, options: mask)?.lowerBound else {
            return ([self], false)
        }
        assert(matchIndex != mismatchIndex)

        let firstOneMatches = matchIndex < mismatchIndex
        var (firstMatchIndex, secondMatchIndex, matchingSet) = firstOneMatches ? (matchIndex, mismatchIndex, untilChangedOn) : (mismatchIndex, matchIndex, antiUntil)
        var runs = [self[firstMatchIndex..<secondMatchIndex]]
        while secondMatchIndex < self.endIndex {
            firstMatchIndex = self.rangeOfCharacter(from: matchingSet, options: mask, range: secondMatchIndex..<self.endIndex)?.lowerBound ?? self.endIndex
            swap(&firstMatchIndex, &secondMatchIndex)
            runs.append(self[firstMatchIndex..<secondMatchIndex])
            matchingSet.invert()
        }
        return (runs, firstOneMatches)

        // This recursive solution also works.
        //return ([self[firstMatchIndex..<secondMatchIndex]] + self[secondMatchIndex..<self.endIndex].consecutiveComponents(untilChangedOn: antiUntil, options: mask).0, firstOneMatches)
    }

}
