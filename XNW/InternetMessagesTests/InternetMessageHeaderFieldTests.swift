//
//  InternetMessageHeaderFieldTests.swift
//  XNW
//
//  Created by Daryle Walker on 2/9/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import XCTest
@testable import InternetMessages


class InternetMessageHeaderFieldTests: XCTestCase {

    // A simple implementation of a header field
    struct SimpleHeaderField: InternetMessageHeaderMutableField {

        var name = ""
        var body = ""

    }

    // Make string that goes beyond 78 characters
    static let tooLongForDisplay = String(repeating: "A", count: 80)
    // Make string that goes beyond 998 octets under UTF-8
    static let tooLongForTransmission = String(repeating: "B", count: 1000)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Test the basic validation code
    func testBasicValidation() {
        typealias SHF = SimpleHeaderField
        typealias IME = InternetMessageError

        // Empty name
        XCTAssertEqual(SHF.invalidationsOn(name: "", flagTooLongForTransmission: false), [IME.headerFieldNameIsTooShort])
        XCTAssertEqual(SHF.invalidationsOn(name: "", flagTooLongForTransmission: true), [IME.headerFieldNameIsTooShort])

        // Invalid characters in the name
        XCTAssertEqual(SHF.invalidationsOn(name: "Héllo", flagTooLongForTransmission: false), [IME.headerFieldNameHasInvalidCharacters])
        XCTAssertEqual(SHF.invalidationsOn(name: "Héllo", flagTooLongForTransmission: true), [IME.headerFieldNameHasInvalidCharacters])

        // Name is too long
        XCTAssertEqual(SHF.invalidationsOn(name: InternetMessageHeaderFieldTests.tooLongForTransmission, flagTooLongForTransmission: false), [])
        XCTAssertEqual(SHF.invalidationsOn(name: InternetMessageHeaderFieldTests.tooLongForTransmission, flagTooLongForTransmission: true), [IME.headerFieldNameIsTooLongForTransmission])

        let borderline = String(repeating: "É", count: 998)
        XCTAssertEqual(SHF.invalidationsOn(name: borderline, flagTooLongForTransmission: false), [IME.headerFieldNameHasInvalidCharacters])
        XCTAssertEqual(SHF.invalidationsOn(name: borderline, flagTooLongForTransmission: true), [IME.headerFieldNameHasInvalidCharacters, IME.headerFieldNameIsTooLongForTransmission])

        // Normal name
        XCTAssertEqual(SHF.invalidationsOn(name: "Hello", flagTooLongForTransmission: false), [])
        XCTAssertEqual(SHF.invalidationsOn(name: "Hello", flagTooLongForTransmission: true), [])

        // Empty body
        XCTAssertEqual(SHF.invalidationsOn(body: "", flagHasInternationalCharacters: false), [])
        XCTAssertEqual(SHF.invalidationsOn(body: "", flagHasInternationalCharacters: true), [])

        // Control character in body
        XCTAssertEqual(SHF.invalidationsOn(body: "W\0rld", flagHasInternationalCharacters: false), [IME.headerFieldBodyHasInvalidAsciiCharacters])
        XCTAssertEqual(SHF.invalidationsOn(body: "W\0rld", flagHasInternationalCharacters: true), [IME.headerFieldBodyHasInvalidAsciiCharacters])

        // Unicode character in body
        XCTAssertEqual(SHF.invalidationsOn(body: "Wørld", flagHasInternationalCharacters: false), [])
        XCTAssertEqual(SHF.invalidationsOn(body: "Wørld", flagHasInternationalCharacters: true), [IME.headerFieldBodyHasInvalidUnicodeCharacters])

        // Control and Unicode characters in body
        XCTAssertEqual(SHF.invalidationsOn(body: "Wø\u{7F}orld", flagHasInternationalCharacters: false), [IME.headerFieldBodyHasInvalidAsciiCharacters])
        XCTAssertEqual(SHF.invalidationsOn(body: "Wø\u{7F}orld", flagHasInternationalCharacters: true), [IME.headerFieldBodyHasInvalidAsciiCharacters, IME.headerFieldBodyHasInvalidUnicodeCharacters])

        // Normal body
        XCTAssertEqual(SHF.invalidationsOn(body: "World", flagHasInternationalCharacters: false), [])
        XCTAssertEqual(SHF.invalidationsOn(body: "World", flagHasInternationalCharacters: true), [])
    }

    // Test the default code for single header field lines
    func testWholeLine() {
        var sample = SimpleHeaderField(name: "Hello", body: "")
        XCTAssertEqual(sample.line, "Hello:")
        sample.body = "World"
        XCTAssertEqual(sample.line, "Hello: World")
        sample.body = " There"
        XCTAssertEqual(sample.line, "Hello: There")
        sample.body = "\tEveryone"
        XCTAssertEqual(sample.line, "Hello: \tEveryone")
    }

    // Test the default code for a wrapped header field line
    func testWrappedLine() {
        var sample = SimpleHeaderField(name: "Hello", body: "")
        XCTAssertEqual(sample.wrappedLineSegments, ["Hello:"])
        sample.body = "\t "
        XCTAssertEqual(sample.wrappedLineSegments, ["Hello: \t "])
        sample.body = " \t"
        XCTAssertEqual(sample.wrappedLineSegments, ["Hello: \t"])
        sample.body = "World"
        XCTAssertEqual(sample.wrappedLineSegments, ["Hello: World"])
        sample.body = "World\t "
        XCTAssertEqual(sample.wrappedLineSegments, ["Hello: World\t "])
        sample.body = "There World"
        XCTAssertEqual(sample.wrappedLineSegments, ["Hello: There World"])
        sample.body = "There,\tWorld "
        XCTAssertEqual(sample.wrappedLineSegments, ["Hello: There,\tWorld "])
        sample.body = InternetMessageHeaderFieldTests.tooLongForDisplay
        XCTAssertEqual(sample.wrappedLineSegments, ["Hello:", " " + InternetMessageHeaderFieldTests.tooLongForDisplay])
        sample.body = "\t" + InternetMessageHeaderFieldTests.tooLongForDisplay
        XCTAssertEqual(sample.wrappedLineSegments, ["Hello: ", "\t" + InternetMessageHeaderFieldTests.tooLongForDisplay])
        sample.body.append(" \t Another Line")
        XCTAssertEqual(sample.wrappedLineSegments, ["Hello: ", "\t" + InternetMessageHeaderFieldTests.tooLongForDisplay, " \t Another Line"])
    }

    // Test validation with wrapped lines
    func testWrappedLineValidation() {
        // Normal name, empty body
        var sample = SimpleHeaderField(name: "Hello", body: "")
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true), [])

        // Not-so-short name
        sample.name = InternetMessageHeaderFieldTests.tooLongForDisplay
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true), [])

        // Excessively-long name
        sample.name = InternetMessageHeaderFieldTests.tooLongForTransmission
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false), [InternetMessageError.headerFieldCouldNotBeWrappedForTransmission, InternetMessageError.headerFieldNameIsTooLongForTransmission])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true), [InternetMessageError.headerFieldCouldNotBeWrappedForTransmission, InternetMessageError.headerFieldNameIsTooLongForTransmission])

        // Normal name and body
        sample.name = "Hello"
        sample.body = "World"
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true), [])

        // International body
        sample.body = "Wørld"
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true), [InternetMessageError.headerFieldBodyHasInvalidUnicodeCharacters])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true), [InternetMessageError.headerFieldBodyHasInvalidUnicodeCharacters])

        // Not-so-short body
        sample.body = InternetMessageHeaderFieldTests.tooLongForDisplay
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true), [])

        // Even longer body, for another segment
        sample.body = " \t" + InternetMessageHeaderFieldTests.tooLongForDisplay + " \t Another Line  "
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true), [])

        // Excessively-long body
        sample.body = InternetMessageHeaderFieldTests.tooLongForTransmission
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: false), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: false, flagHasInternationalCharacters: true), [])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: false), [InternetMessageError.headerFieldCouldNotBeWrappedForTransmission])
        XCTAssertEqual(sample.invalidations(flagTooLongForTransmission: true, flagHasInternationalCharacters: true), [InternetMessageError.headerFieldCouldNotBeWrappedForTransmission])
    }

}
