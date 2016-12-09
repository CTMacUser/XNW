//
//  CharacterSets.swift
//  XNW
//
//  Created by Daryle Walker on 5/5/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import Foundation


/// The various character sets used in parts of Internet Messages.
public enum CharacterSets {

    /// The ASCII characters from Unicode.
    public static let ascii = NSCharacterSet(range: NSRange(location: 0, length: 128))
    /// All the Unicode characters past the ASCII range.
    public static let postAscii = CharacterSets.ascii.invertedSet

    // Sets from the Core Rules, i.e. Section B.1 of RFC 5234.
    /// Alphabet (ALPHA in RFC 5234)
    public static let alpha = NSCharacterSet(charactersInString: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    /// Binary digits (BIT in RFC 5234)
    public static let binaryDigits = NSCharacterSet(charactersInString: "01")
    /// ASCII without the NUL character.  (CHAR in RFC 5234)
    public static let regular = NSCharacterSet(range: NSRange(location: 0x01, length: 0x7F - 0x01 + 1))
    /// Control characters (CTL in RFC 5234)
    public static let controls = NSCharacterSet(range: NSRange(location: 0, length: 0x20)) + NSCharacterSet(charactersInString: "\u{7F}")
    /// Decimal digits (DIGIT in RFC 5234)
    public static let decimalDigits = NSCharacterSet(charactersInString: "0123456789")
    /// Hexadecimal digits (HEXDIG in RFC 5234); excludes miniscule letters
    public static let hexadecimalDigits = NSCharacterSet(charactersInString: "0123456789ABCDEF")
    /// The 8-bit extension for ASCII.  In Unicode, this would be ISO-Latin-1.  (OCTET in RFC 5234, modulo encoding)
    public static let ascii8bit = NSCharacterSet(range: NSRange(location: 0, length: 1 << 8))
    /// The normal characters, i.e. printable US-ASCII.  (VCHAR in RFC 5234)
    public static let visible = NSCharacterSet(range: NSRange(location: 0x21, length: 0x7E - 0x21 + 1))
    /// In-line whitespace.  (WSP in RFC 5234)
    public static let whitespace = NSCharacterSet(charactersInString: " \t")

    /// Line-breaking whitespace, without specifying actual use.  (CR and LF, parts of CRLF in RFC 5234)
    public static let lineBreakers = NSCharacterSet(charactersInString: "\r\n")

    // Sets from Internet Messages (RFC 5322)
    /// Normal header text.  (No controls, NUL, CR, nor LF, besides CRLF sequences which get folded away.)
    public static let normalHeaderText = CharacterSets.visible + CharacterSets.whitespace

    /// Text for header field names; ftext.
    public static let fieldName = CharacterSets.visible - NSCharacterSet(charactersInString: ":")
    /// Text banned from being in header field bodies during strict parsing; ~(unstructred - obs-unstruct).  When parsing is lax, all characters are allowed!
    public static let fieldBodyBannedStrict = CharacterSets.ascii - CharacterSets.normalHeaderText
    /// Text banned from being in a message field body; ~text.  When parsing is lax, all characters are allowed!
    public static let messageBodyBannedStrict = CharacterSets.lineBreakers + NSCharacterSet(charactersInString: "\0")

}

/// The character sequences for line breaks.
public enum LineBreaks {

    /// The line break for Cocoa strings.
    public static let internalString = "\n"
    /// The line break for Internet Messages.  (CRLF in RFC 5234)
    public static let internetMessageString = "\r\n"

}

/// - returns: The union of `augend` and `addend`
func +(augend: NSCharacterSet, addend: NSCharacterSet) -> NSCharacterSet {
    let union = augend.mutableCopy() as! NSMutableCharacterSet
    union.formUnionWithCharacterSet(addend)
    return union
}

/// - returns: The intersection of `multiplier` and `multiplicand`
func *(multiplier: NSCharacterSet, multiplicand: NSCharacterSet) -> NSCharacterSet {
    let intersection = multiplier.mutableCopy() as! NSMutableCharacterSet
    intersection.formIntersectionWithCharacterSet(multiplicand)
    return intersection
}

/// - returns: The difference of `minuend` from `subtrahend`
func -(minuend: NSCharacterSet, subtrahend: NSCharacterSet) -> NSCharacterSet {
    let difference = minuend.mutableCopy() as! NSMutableCharacterSet
    difference.formIntersectionWithCharacterSet(subtrahend.invertedSet)
    return difference
}
