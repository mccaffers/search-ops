// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON
import RealmSwift

@testable import SearchOps

@available(iOS 16.0.0, *)
final class ResponseFieldTests: XCTestCase {

  // Verifies the correct retrieval and count of fields from a simulated ElasticSearch response.
  func testFields() async throws {
    // Load the same static response file used in other tests to ensure consistency.
    let response = try SearchOpsTests().OpenFile(filename: "response.1")
    // Invoke the function that extracts fields from the ElasticSearch response.
    let output = Fields.getFields(input: response)
  
    // Check that the number of fields extracted matches the expected count, confirming the parser's accuracy.
    XCTAssertEqual(output.count, 7)
  }
  
  // Similar to testFields, but for a different response potentially containing more complex or nested data structures.
  func testFieldsWithDepth() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.2")
    let output = Fields.getFields(input: response)
    
    XCTAssertEqual(output.count, 8)
  }
  
  // Tests parsing fields when the response includes arrays, which can complicate parsing logic.
  func testFieldsWithArray() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.3")
    let output = Fields.getFields(input: response)
    
    XCTAssertEqual(output.count, 17)
  }
  
  // Tests the handling of large nested objects within a response, a common challenge in parsing complex JSON data.
  func testFieldsWithLargeNestedObject() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.6")
    let output = Fields.getFields(input: response)
    
    XCTAssertEqual(output.count, 26)
  }
  

}
