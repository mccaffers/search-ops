// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import SearchOps

// Ensures that this class and its methods are only available on iOS 16.0.0 and later.
@available(iOS 16.0.0, *)
final class ElasticTests: XCTestCase {
  
  // Setup method called before each test, used to configure or prepare the test environment.
  @MainActor override func setUp() {
    super.setUp()
    // Initializes an in-memory Realm database for testing, which provides a clean state for each test.
    _ = RealmManager().getRealm(inMemory: true)
  }
  
  // Tests the system's response to a query shard exception, an error specific to ElasticSearch.
  func testQueryShardException() async throws {
    // Loads a mock response that simulates a query shard exception.
    let response = try SearchOpsTests().OpenFile(filename: "query_shard_exception")
    // Processes the response to simulate fetching objects from an ElasticSearch server.
    let output = Search.getObjects(input: response)
    
    // Asserts that no data objects are returned due to the error.
    let objectCount = output.data.count
    XCTAssertEqual(objectCount, 0)
    
    // Asserts that the error message is as expected, checking the error handling correctness.
    let errorMessage = output.error
    XCTAssertEqual(errorMessage, "Failed to parse query [headers.accept:application/json]")
  }
  
  // Tests handling of a simulated internal server error from ElasticSearch.
  func testInternalError() async throws {
    // Loads a mock response simulating an internal server error.
    let response = try SearchOpsTests().OpenFile(filename: "internal_error")
    // Processes the response, expecting no data due to the error.
    let output = Search.getObjects(input: response)
    
    // Confirms that no data objects are returned.
    let objectCount = output.data.count
    XCTAssertEqual(objectCount, 0)
    
    // Validates that the error message matches the expected internal error message.
    let errorMessage = output.error
    XCTAssertEqual(errorMessage, "{    \"message\": \"Internal server error\"}")
  }
  
  // Tests the correct handling and parsing of a valid JSON response.
  func testValidJSONResponse() async throws {
    // Loads a simple JSON response.
    let jsonResponse = try SearchOpsTests().OpenFile(filename: "test")
    Request.mockedSession = MockURLSession(response: jsonResponse)
    
    // Configures host details for the simulated request.
    let esDetails = HostDetails()
    esDetails.host = HostURL()
    esDetails.host?.url = "google.com"
    esDetails.host?.port = "443"
    esDetails.host?.scheme = HostScheme.HTTPS
    
    // Performs a simulated network request, expecting a JSON response.
    let output = await Search.testHost(serverDetails: esDetails).parsed
    
    // Parses the JSON and verifies the "hello" key's value.
    let json = try! JSON(data: Data(output!.data))
    let hello = json["hello"].string
    
    XCTAssertEqual(hello, "world")
  }
  
  // Tests the system's handling of invalid input, verifying robustness and error handling.
  func testInvalidInput() async throws {
    // Loads a mock response with invalid JSON or unexpected format.
    let jsonResponse = try SearchOpsTests().OpenFile(filename: "randomText")
    Request.mockedSession = MockURLSession(response: jsonResponse)
    
    // Executes the test, expecting specific handling or error message.
    let output = await Search.testHost(serverDetails: HostDetails())
    
    // Verifies that the processed output is as expected, focusing on error handling.
    XCTAssertEqual(output.parsed?.trimmingCharacters(in: .whitespacesAndNewlines), "abc")
  }
  
  // Tests indexing statistics retrieval from ElasticSearch.
  func testIndex() async throws {
    // Loads a JSON response that could represent indexing statistics.
    let jsonResponse = try SearchOpsTests().OpenFile(filename: "test")
    Request.mockedSession = MockURLSession(response: jsonResponse)
    
    // Executes an index statistics retrieval.
    let output = await Indicies.indexStats(serverDetails: HostDetails(), index: "")
    
    // Verifies that the response is correctly retrieved and matches the expected JSON structure.
    XCTAssertEqual(output, jsonResponse)
  }
  
  // Tests handling when an error response is received from ElasticSearch.
  func testGetErrorResponse() async throws {
    // Loads a mock error response.
    let response = try SearchOpsTests().OpenFile(filename: "error")
    
    // Parses the response, expecting no valid data and focusing on error handling.
    let objects = Search.getObjects(input: response)
    
    // Asserts that no data is returned, confirming error handling efficiency.
    XCTAssertEqual(0, objects.data.count)
  }
}
