// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps
import SwiftyJSON

final class StringExtensionsTests: XCTestCase {
  
  // Tests for isInt
  func testIsInt() {
    XCTAssertTrue("123".isInt, "String containing only digits should return true")
    XCTAssertFalse("abc".isInt, "Alphabetic string should return false")
    XCTAssertFalse("123abc".isInt, "Alphanumeric string should return false")
    XCTAssertFalse("123.456".isInt, "String containing a decimal should return false")
    XCTAssertTrue("-123".isInt, "Negative integers should be recognized as integers")
    XCTAssertTrue("+123".isInt, "String with plus sign should return true")
    XCTAssertFalse("".isInt, "Empty string should return false")
    XCTAssertFalse("123\n".isInt, "String with newline should return false")
    XCTAssertFalse(" 123 ".isInt, "String with spaces around should return false")
  }
  
  // Tests for truncated(to:, addEllipsis:)
  func testTruncated() {
    // Test truncation without ellipsis
    XCTAssertEqual("Hello world".truncated(to: 5, addEllipsis: false), "Hello", "Should truncate to 'Hello'")
    XCTAssertEqual("Hello".truncated(to: 10, addEllipsis: false), "Hello", "Should return full string if under max length")
    
    // Test truncation with ellipsis
    XCTAssertEqual("Hello world".truncated(to: 8), "Hello...", "Should truncate with ellipsis")
    XCTAssertEqual("Hello".truncated(to: 10), "Hello", "Should return full string if under max length")
    XCTAssertEqual("Hello world".truncated(to: 3), "", "Truncation limit too small for ellipsis should return empty string")
    XCTAssertEqual("Hello world".truncated(to: 4), "H...", "Truncation limit allows only ellipsis")
    XCTAssertEqual("One or more errors occurred. (Year, Month, and Day parameters describe an un-representable DateTime.)".truncated(to: 100),
                   "One or more errors occurred. (Year, Month, and Day parameters describe an un-representable DateTi...", "Truncation limit allows only ellipsis")
    
    // Edge cases
    XCTAssertEqual("".truncated(to: 5), "", "Empty string should return empty")
    XCTAssertEqual("A".truncated(to: 1), "A", "Single character should return as is")
    XCTAssertEqual("Test".truncated(to: 1, addEllipsis: false), "T")
    XCTAssertEqual("Test".truncated(to: 4), "Test")
  }
  
  func testPrettifyJSON_ValidJSON() {
    let jsonString = """
            {
                "name": "John",
                "age": 30,
                "city": "New York"
            }
            """
    
    let prettifiedString = jsonString.prettifyJSON()
    
    XCTAssertEqual(prettifiedString, """
            {
              "name" : "John",
              "age" : 30,
              "city" : "New York"
            }
            """)
  }
  
  func testPrettifyJSON_EmptyObject() {
    let jsonString = "{}"
    
    let prettifiedString = jsonString.prettifyJSON()
    
    XCTAssertEqual(prettifiedString, "{}")
  }
  
  func testPrettifyJSON_EmptyArray() {
    let jsonString = "[]"
    
    let prettifiedString = jsonString.prettifyJSON()
    
    XCTAssertEqual(prettifiedString, "[]")
  }
  
  func testPrettifyJSON_WithWhitespaceInsideEmptyObject() {
    let jsonString = "{   \n  }"
    
    let prettifiedString = jsonString.prettifyJSON()
    
    XCTAssertEqual(prettifiedString, "{}")
  }
  
  func testPrettifyJSON_WithWhitespaceInsideEmptyArray() {
    let jsonString = "[   \n  ]"
    
    let prettifiedString = jsonString.prettifyJSON()
    
    XCTAssertEqual(prettifiedString, "[]")
  }
  
  func test2() {
    let jsonString = "{\n  \"runIteration\" : \"0\",\n  \"hResult\" : 1,\n  \"className\" : \"trading_exception.TradingException\",\n  \"data\" : {\n\n  }}"
    
    let prettifiedString = jsonString.prettifyJSON()
    
    XCTAssertEqual(prettifiedString, "{\n  \"hResult\" : 1,\n  \"data\" : {},\n  \"className\" : \"trading_exception.TradingException\",\n  \"runIteration\" : \"0\"\n}")
  }
}
