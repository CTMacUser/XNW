//
//  InternetMessageLineCategoryTests.swift
//  XNW
//
//  Created by Daryle Walker on 2/27/17.
//  Copyright © 2017 Daryle Walker. All rights reserved.
//

import XCTest
@testable import InternetMessages


class InternetMessageLineCategoryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Check each line category
    func testInternetMessageLineCategory() {
        typealias IMLC = InternetMessageLineCategory

        let emptyLine = ""
        let allBlankLine = " \t   \t "
        let continuationLine = "\tContinuation"
        let anotherContinuationLine = " Not: Really a Header Field starter!"
        let headerStarter1 = "But: This one is a starter"
        let headerStarterWithTrailingSpace = "This  \t :is a starter too"
        let headerStarterNoBody = "So-Is-This:"
        let otherLine1 = ": but this isn't anything special!'"
        let otherLine2 = "and a line without a colon and no starting blank is also non-special"

        XCTAssert(IMLC.categorize(line: emptyLine.data(using: .utf8)!) == IMLC.empty)
        XCTAssertEqual(IMLC.categorize(line: allBlankLine.data(using: .utf8)!), IMLC.allBlanks)
        XCTAssertEqual(IMLC.categorize(line: continuationLine.data(using: .utf8)!), IMLC.headerContinuation)
        XCTAssertEqual(IMLC.categorize(line: anotherContinuationLine.data(using: .utf8)!), IMLC.headerContinuation)
        XCTAssertEqual(IMLC.categorize(line: headerStarter1.data(using: .utf8)!), IMLC.headerStart(name: Array("But".data(using: .utf8)!), body: Array(" This one is a starter".data(using: .utf8)!)))
        XCTAssertEqual(IMLC.categorize(line: headerStarterWithTrailingSpace.data(using: .utf8)!), IMLC.headerStart(name: Array("This".data(using: .utf8)!), body: Array("is a starter too".data(using: .utf8)!)))
        XCTAssertEqual(IMLC.categorize(line: headerStarterNoBody.data(using: .utf8)!), IMLC.headerStart(name: Array("So-Is-This".data(using: .utf8)!), body: []))
        XCTAssertEqual(IMLC.categorize(line: otherLine1.data(using: .utf8)!), IMLC.other)
        XCTAssertEqual(IMLC.categorize(line: otherLine2.data(using: .utf8)!), IMLC.other)
    }

}
