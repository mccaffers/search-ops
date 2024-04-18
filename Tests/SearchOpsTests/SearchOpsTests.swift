// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import SearchOps

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

