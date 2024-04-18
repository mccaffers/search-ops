// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import SearchOps

@available(iOS 16.0.0, *)
final class RequestTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // TODO
    // Use in memory realm
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
  }
  
  func testValidJSONResponse() async throws {
    
    
    // {"hello":"world"}
    let jsonResponse = try! SearchOpsTests().OpenFile(filename: "test")
    Request.mockedSession = MockURLSession(response: jsonResponse)
    
    // blank object
    let esDetails = HostDetails()
    
    
    // blank request, validating response handling
    let output = await Request()
      .invoke(serverDetails: esDetails,
              endpoint: "/")
    
    if let data = output.data {
      let json = try! JSON(data: data)
      let hello = json["hello"].string
      
      XCTAssertEqual(hello, "world")
    } else {
      XCTFail("Missing response")
    }
    
  }
  
  func testInvalidJSONResponse() async throws {
    
    
    Request.mockedSession = MockURLSession(response: "null")
    
    // blank object
    let esDetails = HostDetails()
    
    // blank request, validating response handling
    let output = await Request()
      .invoke(serverDetails: esDetails,
              endpoint: "/")
    
    if let data = output.data {
      let result = String(bytes: data, encoding: String.Encoding.utf8) ?? "";
      XCTAssertEqual(result, "null")
    } else {
      XCTFail("Missing response")
    }
    
    
  }
  
  func testInvalidEndpoint() async throws {
    
    Request.mockedSession = MockURLSession(response: "null")
    
    // blank object
    let esDetails = HostDetails()
    
    // blank request, validating response handling
    let output = await Request()
      .invoke(serverDetails: esDetails,
              endpoint: "@")
    
    if let data = output.data {
      let result = String(bytes: data, encoding: String.Encoding.utf8) ?? "";
      XCTAssertEqual(result, "null")
    } else {
      XCTFail("Missing response")
    }
    
    
  }
  
  func testPostRequest() async throws {
    
    Request.mockedSession = MockURLSession(response: "json")
    
    // blank object
    let esDetails = HostDetails()
    
    let json = "{\"query\":{\"bool\":{\"must\":[{\"query_string\":{\"query\":\"*\"}}]}}}"
    
    // blank request, validating response handling
    let validInput = await Request()
      .invoke(serverDetails: esDetails,
              endpoint: "/",
              json: json)
    
    if let data = validInput.data {
      let result = String(bytes: data, encoding: String.Encoding.utf8) ?? "";
      XCTAssertEqual(result, "json")
    } else {
      XCTFail("Missing response")
    }
    
    let invalidInput = await Request()
      .invoke(serverDetails: esDetails,
              endpoint: "/",
              json: "null")
    
    if let data = invalidInput.data {
      let result = String(bytes: data, encoding: String.Encoding.utf8) ?? "";
      XCTAssertEqual(result, "json")
    } else {
      XCTFail("Missing response")
    }
    
    
  }
  
  func testThrowingRequest() async throws {
    
    Request.mockedSession = MockURLSession(response: "null", exception: true)
    
    // blank object
    let esDetails = HostDetails()
    
    let output = await Request()
      .invoke(serverDetails: esDetails, endpoint: "/")
    
    XCTAssertNil(output.data)
    
  }
  
  
}
