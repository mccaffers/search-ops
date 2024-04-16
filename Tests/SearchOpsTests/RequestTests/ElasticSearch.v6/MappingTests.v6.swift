// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import SearchOps

@available(iOS 16.0.0, *)
final class ElasticSearch_v6_MappingTests: XCTestCase {
  
  override func setUpWithError() throws {
      try? RealmManager.DeleteRealmDatabase()
  }
  
  @MainActor
  func testObjectsElasticv6() async throws {
    
    let response = try! SearchOpsTests().OpenFile(filename: "v6_mapping")
    Request.mockedSession = MockURLSession(response: response)
    let output = await IndexMap.indexMappings(serverDetails: HostDetails(), index: "")
    
    XCTAssertEqual(output.count, 17)
    
  }
}



