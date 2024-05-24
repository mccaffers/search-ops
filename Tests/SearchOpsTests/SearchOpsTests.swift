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
public class SearchOpsTests: XCTestCase {
  
  func OpenFile(filename:String) throws -> String {
    
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
