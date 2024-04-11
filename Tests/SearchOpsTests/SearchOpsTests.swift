// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
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

@available(iOS 15.0.0, *)
final class SearchOpsTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    

    
    func OpenFile(filename:String) throws -> String {

//        let mypath = Bundle.module.url(forResource: filename, withExtension: "json")
        
        if let filepath = Bundle.module.url(forResource: filename, withExtension: "json") {
            do {
                let contents = (try Data(contentsOf: filepath.absoluteURL).string)!
                return contents
            } catch {
                print("Cannot read contents of JSON file " + filename)
            }
        } else {
            print("Missing JSON file")
        }
        return ""
        
    }
	


}

