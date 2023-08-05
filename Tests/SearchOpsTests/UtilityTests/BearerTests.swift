//
//  BearerTests.swift
//  SearchOpsTests
//
//  Created by Ryan McCaffery on 11/04/2023.
//

import XCTest

@testable import SearchOps

final class BearerTests: XCTestCase {

    func testBearer() throws {
        let output = AuthBuilder.MakeBearer(username: "user", password: "pass")
        let expected = "dXNlcjpwYXNz"
        XCTAssertEqual(output, expected)
    }
    
    func testEmptyBearer() throws {
        let output = AuthBuilder.MakeBearer(username: "", password: "")
        let expected = "Og=="
        XCTAssertEqual(output, expected)
    }
    
}
