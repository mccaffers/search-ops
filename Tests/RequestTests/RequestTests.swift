// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import Search_Ops

// Marks this class as available for iOS 16.0.0 and later, ensuring it uses features compatible with this iOS version.
@available(iOS 16.0.0, *)
final class RequestTests: XCTestCase {
  
  // Setup method called before each test to configure necessary environments or mocks.
  override func setUp() {
    super.setUp()
    // Suggestion to use an in-memory Realm instance for isolated testing environments.
    // Useful for database tests that need a clean state and no side effects.
  }
  
  // Tests a valid JSON response to ensure that the request handling and JSON parsing work as expected.
  func testValidJSONResponse() async throws {
    // Loads a JSON file with a simple object to mock a valid server response.
    let jsonResponse = try! SearchOpsTests().OpenFile(filename: "test")
    Request.mockedSession = MockURLSession(response: jsonResponse) as! any URLSessionProtocol
    
    // Mock setup of host details; essentially empty for this test.
    let esDetails = HostDetails()
    
    // Performs the request to check if the system correctly handles and parses the JSON.
    let output = await Request().invoke(serverDetails: esDetails, endpoint: "/")
    
    // Asserts that the response contains the expected 'hello' key with 'world' as its value.
    if let data = output.data {
      let json = try! JSON(data: data)
      let hello = json["hello"].string
      
      XCTAssertEqual(hello, "world")
    } else {
      XCTFail("Missing response")
    }
  }
  
  // Tests the handling of an invalid JSON response to ensure that such responses are gracefully managed.
  func testInvalidJSONResponse() async throws {
    // Mocks a 'null' responsue
    Request.mockedSession = MockURLSession(response: "null")
    
    let esDetails = HostDetails()
    
    // Checks that the system can receive and correctly identify a 'null' response.
    let output = await Request().invoke(serverDetails: esDetails, endpoint: "/")
    
    if let data = output.data {
      let result = String(bytes: data, encoding: .utf8) ?? ""
      XCTAssertEqual(result, "null")
    } else {
      XCTFail("Missing response")
    }
  }
  
  // Tests the system's behavior when hitting an invalid endpoint.
  func testInvalidEndpoint() async throws {
    // Mock setup for an invalid endpoint response.
    Request.mockedSession = MockURLSession(response: "null")
    
    let esDetails = HostDetails()
    
    // Verifies handling of requests to an invalid endpoint.
    let output = await Request().invoke(serverDetails: esDetails, endpoint: "@")
    
    if let data = output.data {
      let result = String(bytes: data, encoding: .utf8) ?? ""
      XCTAssertEqual(result, "null")
    } else {
      XCTFail("Missing response")
    }
  }
  
  // Tests POST requests to ensure that JSON body data is properly sent and responses are handled correctly.
  func testPostRequest() async throws {
    // Mocks a response for JSON data.
    Request.mockedSession = MockURLSession(response: "json")
    
    let esDetails = HostDetails()
    let json = "{\"query\":{\"bool\":{\"must\":[{\"query_string\":{\"query\":\"*\"}}]}}}"
    
    // Tests sending a valid JSON string as a POST request and checks the response.
    let validInput = await Request().invoke(serverDetails: esDetails, endpoint: "/", json: json)
    
    if let data = validInput.data {
      let result = String(bytes: data, encoding: .utf8) ?? ""
      XCTAssertEqual(result, "json")
    } else {
      XCTFail("Missing response")
    }
    
    // Tests handling of sending 'null' as a JSON body to simulate error conditions.
    let invalidInput = await Request().invoke(serverDetails: esDetails, endpoint: "/", json: "null")
    
    if let data = invalidInput.data {
      let result = String(bytes: data, encoding: .utf8) ?? ""
      XCTAssertEqual(result, "json")
    } else {
      XCTFail("Missing response")
    }
  }
  
  // Tests the system's error handling by simulating a throwing condition within the request method.
  func testThrowingRequest() async throws {
    // Sets up a mocked session that simulates an exception, such as a network error.
    Request.mockedSession = MockURLSession(response: "null", exception: true)
    
    let esDetails = HostDetails()
    
    // Executes the request to test error handling when an exception is thrown.
    let output = await Request().invoke(serverDetails: esDetails, endpoint: "/")
    
    // Asserts that no data is returned, as expected in error conditions.
    XCTAssertNil(output.data)
  }
  
}
