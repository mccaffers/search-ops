// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import Search_Ops

// Using the latest available iOS version for compatibility
@available(iOS 16.0.0, *)

// Defines a test class for ElasticSearch V5 mappings within the SearchOps package.
// This class is designed to test the parsing and handling of ElasticSearch V5 mapping responses.
final class ElasticSearchV5MappingTests: XCTestCase {
    
    // Setup method executed before each test in this class.
    // It initializes a Realm in-memory database which is useful for testing
    // because it doesn't persist data and avoids test side effects.
    @MainActor
    override func setUp() {
        // Initialize an in-memory Realm database; this is particularly useful for unit tests where
        // you do not want to have persistent storage or need to reset the state before each test.
        _ = RealmManager().getRealm(inMemory: true)
    }
    
    // Test method to verify if the ElasticSearch V5 mapping data parsing works as expected.
    // This is an asynchronous test, reflecting the needs of network-based data retrieval.
    @MainActor
    func testObjectsElasticv5() async throws {
        // Simulating file retrieval which might mimic retrieving a response from a local test bundle
        // or a configuration file that mimics the ElasticSearch mapping format.
        let response = try! SearchOpsTests().OpenFile(filename: "v5_mapping")
        
        // Setting up a mocked network session to simulate network interactions.
        // This setup is crucial for unit tests to decouple from actual network calls,
        // allowing for consistent and repeatable tests.
        Request.mockedSession = MockURLSession(response: response)
        
        // Invoking the method under test with mocked network conditions.
        // 'IndexMap.indexMappings' is expected to process the mapping data and extract relevant mappings.
        let output = await IndexMap.indexMappings(serverDetails: HostDetails(), index: "")
        
        // Asserts that the expected number of mappings is returned.
        // This is a direct way to check if the parsing logic is correctly implemented
        // and is handling the input as expected.
        XCTAssertEqual(output.count, 3)
    }
}
