//
//  IPv4AddressTests.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/07/17.
//
//

import XCTest

class IPv4AddressTests: XCTestCase {
    func testInit() {
        let a = IPv4Address(str: "10.0.0.1")
        XCTAssertNotNil(a)
        XCTAssertEqual(a!.num, 0x0a000001)
    }
    
    func testString() {
        let a = IPv4Address(str: "10.0.0.1")!
        XCTAssertEqual(a.string, "10.0.0.1")
    }
}
