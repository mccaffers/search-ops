// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

class AuthBuilderTests: XCTestCase {
  
  // Test for ConvertCloudIDIntoHost with empty ID
  func testConvertCloudIDIntoHost_EmptyIDReturnsEmpty() {
    let result = AuthBuilder.ConvertCloudIDIntoHost(cloudID: "")
    XCTAssertEqual(result.0, "", "URL should be empty for empty cloudID")
    XCTAssertEqual(result.1, "", "Port should be empty for empty cloudID")
  }
  
  // Test for ConvertCloudIDIntoHost with invalid format
  func testConvertCloudIDIntoHost_InvalidFormatReturnsEmpty() {
    let result = AuthBuilder.ConvertCloudIDIntoHost(cloudID: "invalidFormat")
    XCTAssertEqual(result.0, "", "URL should be empty for invalid format")
    XCTAssertEqual(result.1, "", "Port should be empty for invalid format")
  }
  
  // Test for ConvertCloudIDIntoHost with valid input
  func testConvertCloudIDIntoHost_ValidInput() {
    let base64String = "someValidString$otherPart".data(using: .utf8)!.base64EncodedString()
    let cloudID = "prefix:\(base64String)"
    let result = AuthBuilder.ConvertCloudIDIntoHost(cloudID: cloudID)
    XCTAssertNotEqual(result.0, "", "URL should not be empty for valid input")
    XCTAssertNotEqual(result.1, "", "Port should not be empty for valid input")
  }
  
  // Test for extractPortFromName with valid port specified
  func testExtractPortFromName_ValidPort() {
    let (host, port) = AuthBuilder.extractPortFromName("example.com:8080", "80")
    XCTAssertEqual(host, "example.com", "Host should be extracted correctly")
    XCTAssertEqual(port, "8080", "Port should be extracted correctly")
  }
  
  // Test for extractPortFromName with no port leading to default usage
  func testExtractPortFromName_NoPortUsesDefault() {
    let (host, port) = AuthBuilder.extractPortFromName("example.com", "80")
    XCTAssertEqual(host, "example.com", "Host should be extracted correctly")
    XCTAssertEqual(port, "80", "Default port should be used when no port is specified")
  }
  
  // Test for MakeBearer to ensure correct Base64 encoding of credentials
  func testMakeBearer() {
    let bearer = AuthBuilder.MakeBearer(username: "user", password: "pass")
    let expectedEncoded = "user:pass".data(using: .utf8)!.base64EncodedString()
    XCTAssertEqual(bearer, expectedEncoded, "Bearer token should be correctly encoded")
  }
}
