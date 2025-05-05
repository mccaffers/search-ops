// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import Search_Ops

// Specifies that this test class is only available in iOS 16.0.0 and later,
// aligning with specific API usages or OS features that are only available from this version.
@available(iOS 16.0.0, *)
final class ElasticSearchV6MappingTests: XCTestCase {
  
  // This function is called before the execution of each test method in the class.
  // It sets up necessary testing environments or conditions.
  @MainActor
  override func setUp() {
    // Initializes an in-memory Realm instance. In-memory databases are particularly useful for tests
    // because they do not persist to disk and are cleaned up after the test, ensuring a clean state for each test.
    _ = RealmManager().getRealm(inMemory: true)
  }
  
  // This is the actual test method for ElasticSearch V6 mapping.
  // It is an asynchronous method, reflecting the asynchronous nature of network requests.
  @MainActor
  func testObjectsElasticv6() async throws {
    // Attempts to load a mock file representing the expected V6 mapping response.
    // The 'try!' is used to force-unwrap the result, assuming that the test environment is correctly set up
    // and the file should be present. In practice, force unwrapping in production code is risky.
    let response = try! SearchOpsTests().OpenFile(filename: "v6_mapping")
    
    // Sets up a mocked session using the response data. Mocking network sessions is crucial for unit testing
    // to decouple the test execution from actual network conditions, making the tests deterministic.
    Request.mockedSession = MockURLSession(response: response)
    
    // Calls the function under test with a mocked network environment and checks the parsing logic.
    // 'await' is used here to wait for the async function to complete, which is essential for
    // handling asynchronous code in Swift.
    let output = await IndexMap.indexMappings(serverDetails: HostDetails(), index: "")
    
    // Asserts that the number of mappings returned from the parsing function matches the expected count.
    // This assertion directly tests whether the function correctly processes the input and
    // provides a straightforward way to verify the functionality.
    XCTAssertEqual(output.count, 17)
  }
}
