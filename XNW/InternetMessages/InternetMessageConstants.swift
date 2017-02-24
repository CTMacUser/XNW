//
//  InternetMessageConstants.swift
//  XNW
//
//  Created by Daryle Walker on 2/7/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation


/// A collection of various constants needed to analyze text in the Internet Message Format, defined by RFC 5322, with international extensions from RFC 6532.
public enum InternetMessageConstants {

    /// The maximum preferred character length per line of a message.  This is a display limit; the combined octet count of the characters' representation is bound by another limit.  For header lines, this is the limit for each segment after line-folding is applied.  This does not include the line-breaking character sequence.
    public static let maximumPreferredCharactersPerLine = 78
    /// The maximum number of octets per line of a message.  This is a limit for NNTP/SMTP/etc line processing.  The octet sequence of a line is the UTF-8 expansion of the line's NFC normalization.  For header lines, this is the limit for each segment after line-folding is applied.  This does not include the line-breaking character sequence.
    public static let maximumAllowedOctetsPerLine = 998

    /* Per RFC 6532, Section 3.1, characters should be externalized as UTF-8 using normalization NFC.
       This corresponds to the "precomposedStringWithCanonicalMapping" property of "String" in Swift 3.
       The NFKC normalization form should never be used as it risks loss of information needed to correctly
       spell people's names.
    */

    /// The set of ASCII characters.
    public static let ascii = CharacterSet(charactersIn: "\0"..."\u{7F}")
    // All Unicode characters past ASCII.  Legal anywhere in internationalized messages except header field names.
    public static let postAscii = ascii.inverted
    /// The visible (i.e. printable) ASCII characters; from RFC 5234, section B.1.
    public static let vchar = CharacterSet(charactersIn: "\u{21}"..."\u{7E}")
    /// In-line white-space, i.e. standard space and horizontal tab; from RFC 5234, section B.1.
    public static let wsp = CharacterSet(charactersIn: " \t")

    /// Characters that can be used in a name of a header field; from RFC 5322, section 3.6.8.
    public static let ftext = CharacterSet(charactersIn: "\u{21}"..."\u{39}").union(CharacterSet(charactersIn: "\u{3B}"..."\u{7E}"))  // There's a bug in `CharacterSet` preventing `vchar.subtracting(CharacterSet(charactersIn: ":"))` from working
    /// Characters that are banned from non-obsolete unstructured header field bodies, including the line-breaking characters only present during line-folding.  Implied from RFC 5322, section 3.2.5.
    public static let bannedFromUnstructured = CharacterSet(charactersIn: "\0"..."\u{8}").union(CharacterSet(charactersIn: "\u{A}"..."\u{1F}")).union(CharacterSet(charactersIn: "\u{7F}"))  // The bug keeps `ascii.subtracting(vchar.union(wsp))` from working too
    /// Characters that are banned from non-obsolete message bodies, assuming LF-only line breaks.  (A carriage-return would be OK only if it preceeded a line-feed.)  Implied from RFC 5322, section 3.5.
    public static let bannedFromBody = CharacterSet(charactersIn: "\0\r")

}
