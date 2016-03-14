//
//  NSDataParseTests.swift
//  LineReader
//
//  Created by Daryle Walker on 3/12/16.
//  Copyright © 2016 Daryle Walker. All rights reserved.
//

import XCTest
import Foundation
@testable import LineReader


class NSDataParseTests: XCTestCase {

    var noData: NSData?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        noData = NSData()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Use a NSData object without stored data.
    func testEmptyData() {
        let node = noData!.parseTree
        XCTAssertNil(node)

        //self.measureBlock { _ = self.noData!.parseTree }
    }

    // Convert a non-empty NSData object.
    func testBasicData() {
        func parseDepth<T>(node: ParseNode<T>) -> Int {
            return 1 + node.followerDepth()
        }

        let dataString = "Hello world"
        let data = (dataString as NSString).dataUsingEncoding(NSASCIIStringEncoding)
        let parse = data!.parseTree
        XCTAssertNotNil(parse)
        XCTAssertEqual(parseDepth(parse!), dataString.utf8.count)
        let terms = parse!.terminals()
        XCTAssertEqual(terms.count, 1)
        XCTAssertEqual(terms[0].count, dataString.utf8.count)
        let termData = NSData(bytes: terms[0], length: terms[0].count * strideof(terms[0].dynamicType.Element.self))
        XCTAssert(termData.isEqualToData(data!))
    }

}
