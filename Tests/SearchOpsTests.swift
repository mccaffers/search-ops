// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import Search_Ops

@available(iOS 15.0.0, *)
public class SearchOpsTests: XCTestCase {
  
  func OpenFile(filename:String) throws -> String {
    
    let testBundle = Bundle(for: SearchOpsTests.self)
    if let filepath = testBundle.url(forResource: filename, withExtension: "json") {
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
