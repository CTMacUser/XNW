//
//  StringAdditionsTests.swift
//  XNW
//
//  Created by Daryle Walker on 2/14/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import XCTest
@testable import InternetMessages


class StringAdditionsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Test finding alternating matches to a set.
    func testConsecutiveComponents() {
        // Empty string case
        let wsp = InternetMessageConstants.wsp
        var result = "".consecutiveComponents(untilChangedOn: wsp)
        XCTAssertEqual(result.0, [])
        XCTAssertNil(result.firstOneMatches)

        // All matching or all non-matching
        result = "NoSpaces".consecutiveComponents(untilChangedOn: wsp)
        XCTAssertEqual(result.0, ["NoSpaces"])
        XCTAssertNotNil(result.firstOneMatches)
        XCTAssertEqual(result.firstOneMatches, false)
        result = "  \t ".consecutiveComponents(untilChangedOn: wsp)
        XCTAssertEqual(result.0, ["  \t "])
        XCTAssertNotNil(result.firstOneMatches)
        XCTAssertEqual(result.firstOneMatches, true)

        // Matching, then non-matching
        result = "\t Second".consecutiveComponents(untilChangedOn: wsp)
        XCTAssertEqual(result.0, ["\t ", "Second"])
        XCTAssertEqual(result.firstOneMatches, true)

        // Non-matching, then matching
        result = "First \t".consecutiveComponents(untilChangedOn: wsp)
        XCTAssertEqual(result.0, ["First", " \t"])
        XCTAssertEqual(result.firstOneMatches, false)

        // Larger run
        result = "This is a test.\t It should pass.".consecutiveComponents(untilChangedOn: wsp)
        XCTAssertEqual(result.0, ["This", " ", "is", " ", "a", " ", "test.", "\t ", "It", " ", "should", " ", "pass."])
        XCTAssertEqual(result.firstOneMatches, false)
    }

}
