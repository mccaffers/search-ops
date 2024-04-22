// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

final class LegacyKeychainManagerTests: XCTestCase {
  
  func testKeychainManagerQueryNotFound() throws {
    let manager = LegacyKeychainManager(keychainOps: MockKeychainOperationsNotFound())
    let response = manager.retrieveLegacyKeychain()
    XCTAssertNil(response)
  }
  
  func testKeychainManagerQueryUnexpected() throws {
    let manager = LegacyKeychainManager(keychainOps: MockKeychainOperationsUnexpected())
    let response = try manager.addLegacyKeychain()
    XCTAssertNil(response)
  }
 
  func testKeychainManagerDeleteFalse() throws {
    let manager = LegacyKeychainManager(keychainOps: MockKeychainOperationsUnexpected())
    let response = manager.deleteLegacyKeychain()
    XCTAssertFalse(response)
  }
  
  func testKeychainManagerDeleteTrue() throws {
    let manager = LegacyKeychainManager(keychainOps: MockKeychainOperationsValidResponse())
    let response = manager.deleteLegacyKeychain()
    XCTAssertFalse(response)
  }
}
