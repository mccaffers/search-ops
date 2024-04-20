// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import SearchOps

@available(iOS 16.0.0, *)


final class ElasticSearchV5MappingTests: XCTestCase {
  
  @MainActor
  override func setUp() {
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
    _ = RealmManager().getRealm(inMemory: true)
  }
  
  @MainActor
  func testObjectsElasticv5() async throws {
    
    let response = try! SearchOpsTests().OpenFile(filename: "v5_mapping")
    Request.mockedSession = MockURLSession(response: response)
    let output = await IndexMap.indexMappings(serverDetails: HostDetails(), index: "")
    
    XCTAssertEqual(output.count, 3)
    
  }
}
