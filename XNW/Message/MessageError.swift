//
//  MessageError.swift
//  XNW
//
//  Created by Daryle Walker on 5/6/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import Foundation


/// Errors from the various functions of this module.
@objc public enum MessageError: Int, ErrorType {

    /// Miscellaneous errors.
    case Unknown

    /// The name of the header field has too few characters.
    case HeaderFieldNameTooShort
    /// The name of the header field has too many characters.
    case HeaderFieldNameTooLong
    /// At least one character in the header field name is outside the permitted set.
    case HeaderFieldNameInvalidCharacters
    /// A word in the body of the header field has too many characters.
    case HeaderFieldBodyWordTooLong
    /// At least one character in the header field body is outside the permitted set.  This only happens in strict mode, since obsolete parsing permits any character.
    case HeaderFieldBodyInvalidCharacters

    /// The length of a body line (i.e. span between two line-break sequences) is too high.  This only happens in strict mode, since obsolete bodies can be any length per line.
    case BodyLineTooLong
    /// At least one character in the body is outside the permitted set.  This only happens in strict mode, since obsolete parsing permits any character.
    case BodyInvalidCharacters

}
