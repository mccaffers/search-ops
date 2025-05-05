// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import Foundation

@testable import Search_Ops

/// A mock URL protocol to intercept and handle all URL loading within a session,
/// used primarily for testing network interactions without making actual network calls.
class MockURLProtocol: URLProtocol {
  
  /// Static handler that defines how to respond to intercepted requests.
  /// It can be set to throw an error to simulate network failures or return specific responses.
  static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
  
  /// Determines whether this protocol can handle the given request.
  /// - Parameter request: The request to be handled.
  /// - Returns: Always returns true as this protocol is meant to handle all requests in the testing scenario.
  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }
  
  /// Returns a canonical version of the request. Not modified in this case, just returns what was passed.
  /// - Parameter request: The request to be handled.
  /// - Returns: The same request that was passed in.
  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }
  
  /// Starts loading the request. This is where the request is intercepted and handled according to the `requestHandler`.
  /// Uses the handler to determine the response to the request and then sends appropriate client callbacks to mimic URL loading behavior.
  override func startLoading() {
    guard let handler = MockURLProtocol.requestHandler else {
      fatalError("Handler is unavailable.")
    }
    
    do {
      // Attempt to get a response from the handler.
      let (response, data) = try handler(request)
      // Notify the client that a response has been received.
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      if let data = data {
        // If data is provided, load it.
        client?.urlProtocol(self, didLoad: data)
      }
      // Notify the client that loading has finished.
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      // Notify the client that loading failed.
      client?.urlProtocol(self, didFailWithError: error)
    }
  }
  
  /// Stops loading the request. This method is required but typically does nothing in mock scenarios.
  /// It's here to fulfill protocol requirements and would be used to cancel the request if needed.
  override func stopLoading() {
    // Typically used to cancel the request. Here, we do nothing.
  }
}
