// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import SearchOps

/// A mock URLSession class used for testing network interactions in the SearchOps application.
/// This class implements the URLSessionProtocol and can simulate network responses, including errors.
class MockURLSession: URLSessionProtocol {
    
    /// The mock response content as a string which will be converted to data.
    let response: String
    
    /// Indicates whether this session should throw an exception.
    let throwsException: Bool
    
    /// The HTTP status code to be used in the mock URL response.
    let status: Int
    
    /// Initializes a new instance of the mock session with specified response data, status code, and exception flag.
    /// - Parameters:
    ///   - response: The response content to return as part of the URLSession data task.
    ///   - status: The HTTP status code to return (default is 200).
    ///   - exception: A Boolean that indicates whether the session should simulate an exception (default is false).
    init(response: String, status: Int = 200, exception: Bool = false) {
        self.response = response
        self.throwsException = exception
        self.status = status
    }
    
    /// A Boolean value indicating whether the data task method was called.
    var dataTaskWasCalled = false
    
    /// Simulates the network data task used in URLSession.
    /// Throws an error if `throwsException` is true, otherwise returns mock data and HTTPURLResponse.
    /// - Parameter request: The URLRequest for which the data task is being simulated.
    /// - Returns: A tuple containing the data from `response` and a simulated URLResponse with the specified `status`.
    /// - Throws: An NSError if `throwsException` is true to simulate network errors.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        
        // Check if the session is set to throw exceptions and throw an NSError if true.
        if throwsException {
            throw NSError(domain: "my error domain", code: 42, userInfo: ["ui1": 12, "ui2": "val2"])
        }
        
        // Convert the response string to Data.
        let data = Data(response.utf8)
        
        // Create a mock HTTPURLResponse with the given status code.
        let response: URLResponse = HTTPURLResponse(url: request.url ?? URL(fileURLWithPath: "example.org"), statusCode: status, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}
