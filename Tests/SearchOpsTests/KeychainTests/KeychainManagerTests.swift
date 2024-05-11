// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

final class KeychainManagerTests: XCTestCase {
  
  func testKeychainManagerQueryNotFound() throws {
    let manager = KeychainManager(keychainOps: MockKeychainOperationsNotFound())
    let response = manager.query()
    XCTAssertNil(response)
  }
  
  func testKeychainManagerQueryUnexpected() throws {
    let manager = KeychainManager(keychainOps: MockKeychainOperationsUnexpected())
    let response = manager.query()
    XCTAssertNil(response)
  }
  
  func testKeychainManagerQueryUnhandledError() throws {
    let manager = KeychainManager(keychainOps: MockKeychainOperationsUnhandledError())
    let response = manager.query()
    XCTAssertNil(response)
  }
  
  func testKeychainManagerQueryValidResponse() throws {
    let manager = KeychainManager(keychainOps: MockKeychainOperationsValidResponse())
    let response = manager.query()
    XCTAssertEqual(response?.count, 64)
  }
  
  func testKeychainManagerQueryKeyThrows() throws {
    let manager = KeychainManager(keychainOps: MockKeychainOperationsValidResponse())
    let response = manager.query()
    XCTAssertEqual(response?.count, 64)
  }
}
