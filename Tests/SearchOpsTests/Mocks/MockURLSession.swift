// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import SearchOps

class MockURLSession: URLSessionProtocol {
    
    let response: String
    let throwsException : Bool
    let status : Int
    
    init(response:String, status: Int = 200, exception: Bool = false) {
        self.response = response
        self.throwsException = exception
        self.status = status
    }
    var dataTaskWasCalled = false
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        
        if throwsException {
            throw NSError(domain: "my error domain", code: 42, userInfo: ["ui1":12, "ui2":"val2"] )
        }
        
        let data = Data(response.utf8)
        
        var response : URLResponse = HTTPURLResponse(url: request.url ?? URL(fileURLWithPath: "example.org"), statusCode: status, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}
