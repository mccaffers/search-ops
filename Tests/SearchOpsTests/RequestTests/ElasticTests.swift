// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import SearchOps

@available(iOS 16.0.0, *)
final class ElasticTests: XCTestCase {
  
  func testQueryShardException() async throws {
    
    let response = try! SearchOpsTests().OpenFile(filename: "query_shard_exception")
    let output = Search.getObjects(input: response)
    
    let objectCount = output.data.count
    XCTAssertEqual(objectCount, 0)
    
    let errorMessage = output.error
    XCTAssertEqual(errorMessage, "Failed to parse query [headers.accept:application/json]")
  }
  
  func testInternalError() async throws {
    
    let response = try! SearchOpsTests().OpenFile(filename: "internal_error")
    let output = Search.getObjects(input: response)
    
    let objectCount = output.data.count
    XCTAssertEqual(objectCount, 0)
    
    let errorMessage = output.error
    XCTAssertEqual(errorMessage, "{    \"message\": \"Internal server error\"}")
  }
  
  func testValidJSONResponse() async throws {
    
    // {"hello":"world"}
    let jsonResponse = try! SearchOpsTests().OpenFile(filename: "test")
    Request.mockedSession = MockURLSession(response: jsonResponse)
    
    // blank object
    let esDetails = HostDetails()
    esDetails.host = HostURL()
    esDetails.host?.url = "google.com"
    esDetails.host?.port = "443"
    esDetails.host?.scheme = HostScheme.HTTPS
    
    // blank request, validating response handling
    let output = await Search.testHost(serverDetails: esDetails).parsed
    
    // check output
    let json = try! JSON(data: Data(output!.data))
    let hello = json["hello"].string
    
    XCTAssertEqual(hello, "world")
    
  }
  
  func testInvalidInput() async throws {
    
    let jsonResponse = try! SearchOpsTests().OpenFile(filename: "randomText")
    Request.mockedSession = MockURLSession(response: jsonResponse)
    
    // blank object
    let esDetails = HostDetails()
    
    // blank request, validating response handling
    let output = await Search.testHost(serverDetails: esDetails)
    
    XCTAssertEqual(output.parsed?.trimmingCharacters(in: .whitespacesAndNewlines), "abc")
    
  }
  
  func testIndex() async throws {
    
    // {"hello":"world"}
    let jsonResponse = try! SearchOpsTests().OpenFile(filename: "test")
    Request.mockedSession = MockURLSession(response: jsonResponse)
    
    // blank object
    let esDetails = HostDetails()
    
    // blank request, validating response handling
    let output = await Indicies.indexStats(serverDetails: esDetails, index: "")
    
    XCTAssertEqual(output, jsonResponse)
    
  }
  
  func testGetErrorResponse() async throws {
    
    // JSON Response
    let response = try! SearchOpsTests().OpenFile(filename: "error")
    
    // Serialise and extracts the JSON array from the response
    let objects = Search.getObjects(input: response)
    
    XCTAssertEqual(0, objects.data.count)
  }
  
}
