// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import Testing

@testable import Search_Ops

struct SearchOpsUnitTests {
  
  @Test func testEquality() {
    let field1 = FieldsArray(name: "FieldA")
    let field2 = FieldsArray(name: "FieldA")
    XCTAssertEqual(field1, field2, "FieldsArray instances with the same name should be equal")
  }
  
}
