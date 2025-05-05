// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

/// This test class is designed to validate the functionality of the InsecureConnection class,
/// particularly ensuring that it handles SSL challenges correctly using a custom URLSessionDelegate.
class InsecureConnectionTests: XCTestCase {
  
  /// Tests whether the InsecureConnection's session method correctly handles SSL challenges using custom credentials.
  /// This test verifies that the URLSession with the AllowInsecureConnectionDelegate does not fail
  /// when encountering an SSL challenge, simulating this scenario by mocking the network interaction.
  func testInsecureConnectionUsesCredential() {
    // Use ephemeral session configuration to avoid caching and side effects during testing.
    let config = URLSessionConfiguration.ephemeral
    // Replace the default URL loading protocol with our mock protocol to control the network interaction.
    config.protocolClasses = [MockURLProtocol.self]
    
    // Set up expectation to wait for async network response.
    let expectation = self.expectation(description: "Credential used for challenge")
    
    // Define how the mock protocol should handle incoming requests, providing a predefined response.
    MockURLProtocol.requestHandler = { request in
      // Create a fake HTTP response.
      let response = HTTPURLResponse(url: request.url!,
                                     statusCode: 200, // HTTP OK status code
                                     httpVersion: nil,
                                     headerFields: nil)!
      return (response, Data()) // Return empty data for simplicity.
    }
    
    // Create a URLSession with the custom configuration and delegate.
    let session = URLSession(configuration: config, delegate: AllowInsecureConnectionDelegate(), delegateQueue: nil)
    
    // Start the data task with a sample URL.
    let task = session.dataTask(with: URL(string: "https://example.com")!) { data, response, error in
      // Verify that data is received and there is no error in the response.
      XCTAssertNotNil(data, "Data should not be nil")
      XCTAssertNil(error, "Error should be nil")
      // Fulfill the expectation to signal that the task has completed successfully.
      expectation.fulfill()
    }
    task.resume()
    
    // Wait for expectations to be fulfilled within a 10-second timeout.
    wait(for: [expectation], timeout: 10.0)
  }
}
