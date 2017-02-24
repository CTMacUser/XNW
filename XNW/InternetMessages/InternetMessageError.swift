//
//  InternetMessageError.swift
//  XNW
//
//  Created by Daryle Walker on 2/11/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import Foundation


public enum InternetMessageError: Int, Error {

    /// When a specific issue hasn't been created yet.
    case unknown

    /// Header field names cannot be empty.
    case headerFieldNameIsTooShort
    /// Header field names can only have the non-space, non-control ASCII characters except the colon.
    case headerFieldNameHasInvalidCharacters
    /// Header field names can't be longer than 998 octets to be sent through SMTP, NNTP, etc.
    case headerFieldNameIsTooLongForTransmission
    /// Header field bodies can't contain the ASCII control characters besides horizontal tab.
    case headerFieldBodyHasInvalidAsciiCharacters
    /// Header field bodies can't directly contain post-ASCII Unicode characters if that option is set.
    case headerFieldBodyHasInvalidUnicodeCharacters
    /// A header field's text; name, separating colon, and body; can't have terms that prevent line-wrapping before 998 octets have spanned.  Either the name is at least that long and/or the body has a term combined with its preceding space that is too long.
    case headerFieldCouldNotBeWrappedForTransmission

    /// Message bodies can't have raw CR for internal representations that use only-LF for line breaks.
    case bodyHasRawCarriageReturn
    /// Message bodies can't have embedded NULs
    case bodyHasEmbeddedNul
    /// Message bodies can't directly contain post-ASCII Unicode characters if that option is set.
    case bodyHasInvalidUnicodeCharacters
    /// Message bodies can't have lines longer than 998 octets.
    case bodyHasLineTooLongForTransmission

}
