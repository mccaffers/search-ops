// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

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
