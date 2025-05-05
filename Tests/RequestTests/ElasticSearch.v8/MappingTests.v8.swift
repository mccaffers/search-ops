// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import Search_Ops

// Marks this test class as available only on iOS 16.0.0 and later.
// This can be due to dependencies on APIs or functionality that are only available starting from this iOS version.
@available(iOS 16.0.0, *)

// Defines a class for testing ElasticSearch V8 mappings. It's marked final to prevent subclassing,
// which is a common practice for test classes to encapsulate test logic specifically for this version.
final class ElasticSearchV8MappingTests: XCTestCase {

  // This setup method is decorated with `@MainActor`, ensuring it runs on the main thread,
  // which is important for tests that might interact with UI or need to ensure thread safety.
  @MainActor
  override func setUp() {
    // Initializes a Realm database in memory, which is a common setup for tests to avoid side effects
    // and ensure that each test starts with a clean database state.
    _ = RealmManager().getRealm(inMemory: true)
  }
  
  // A test method that is responsible for checking the mapping configuration for ElasticSearch V8.
  // It's an asynchronous method, allowing it to perform async operations such as network calls.
  @MainActor
  func testMappingElasticv8() async throws {
    // Tries to open a file that presumably contains a mock response for a V8 mapping.
    // The use of `try!` indicates that the test assumes the file must exist and be accessible;
    // however, using `try?` or proper error handling could be safer to prevent crashes in case of errors.
    let response = try! SearchOpsTests().OpenFile(filename: "v8_mapping")
    
    // Mocks a network session to simulate network interactions, using the mock response loaded earlier.
    // This approach is crucial for isolating the test from real network conditions and making it reproducible.
    Request.mockedSession = MockURLSession(response: response)
    
    // Calls the actual method under test, which fetches and parses the index mappings from ElasticSearch V8.
    // `await` is used here to handle the asynchronous operation within this test.
    let output = await IndexMap.indexMappings(serverDetails: HostDetails(), index: "")
    
    // Assigns the count of fields (or mappings) parsed to a local variable for clearer assertion.
    let fieldsCount = output.count
    
    // Asserts that the number of fields parsed matches the expected count of 16,
    // verifying that the mapping is parsed correctly and completely.
    XCTAssertEqual(fieldsCount, 16)
  }
  
  @MainActor
  func testMappingElasticAllv8small() async throws {
    // Tries to open a file that presumably contains a mock response for a V8 mapping.
    // The use of `try!` indicates that the test assumes the file must exist and be accessible;
    // however, using `try?` or proper error handling could be safer to prevent crashes in case of errors.
    let response = try! SearchOpsTests().OpenFile(filename: "_all_mapping_v8_small")
    
    // Calls the actual method under test, which fetches and parses the index mappings from ElasticSearch V8.
    // `await` is used here to handle the asynchronous operation within this test.
    let output = await IndexMap.indexMappingsResponseToArray(response)
    
    // Assigns the count of fields (or mappings) parsed to a local variable for clearer assertion.
    let fieldsCount = output.count
    
    // Asserts that the number of fields parsed matches the expected count of 16,
    // verifying that the mapping is parsed correctly and completely.
    XCTAssertEqual(fieldsCount, 20)
  }
  
  @MainActor
  func testMappingElasticAllv8() async throws {
    // Tries to open a file that presumably contains a mock response for a V8 mapping.
    // The use of `try!` indicates that the test assumes the file must exist and be accessible;
    // however, using `try?` or proper error handling could be safer to prevent crashes in case of errors.
    let response = try! SearchOpsTests().OpenFile(filename: "_all_mapping_v8")
    
    // Calls the actual method under test, which fetches and parses the index mappings from ElasticSearch V8.
    // `await` is used here to handle the asynchronous operation within this test.
    let output = await IndexMap.indexMappingsResponseToArray(response)
    
    // Assigns the count of fields (or mappings) parsed to a local variable for clearer assertion.
    let fieldsCount = output.count
    
    // Asserts that the number of fields parsed matches the expected count of 16,
    // verifying that the mapping is parsed correctly and completely.
    XCTAssertEqual(fieldsCount, 39)
  }
}
