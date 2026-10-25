// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

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
  
  func testKeychainManagerReadNotFound() throws {
    let manager = KeychainManager(keychainOps: MockKeychainOperationsNotFound())
    XCTAssertThrowsError(try manager.read()) { error in
      XCTAssertEqual(error as? KeychainManagerError, KeychainManagerError.noItemFound)
    }
  }
  
  // A denied or failed read must not look like a missing key
  func testKeychainManagerReadUnhandledError() throws {
    let manager = KeychainManager(keychainOps: MockKeychainOperationsUnhandledError())
    XCTAssertThrowsError(try manager.read()) { error in
      XCTAssertEqual(error as? KeychainManagerError, KeychainManagerError.unhandledError(status: 1))
    }
  }
  
  func testKeychainManagerReadValidResponse() throws {
    let manager = KeychainManager(keychainOps: MockKeychainOperationsValidResponse())
    XCTAssertEqual(try manager.read().count, 64)
  }
  
  func testKeychainManagerAddStoresKey() throws {
    let manager = KeychainManager(keychainOps: MockKeychainOperationsValidResponse())
    let key = try manager.add(input: nil)
    XCTAssertEqual(key?.count, 64)
  }
  
  // A key the Keychain didn't store would encrypt a realm nobody can open again
  func testKeychainManagerAddThrowsWhenNotStored() throws {
    let manager = KeychainManager(keychainOps: MockKeychainOperationsAddFails())
    XCTAssertThrowsError(try manager.add(input: nil)) { error in
      XCTAssertEqual(error as? KeychainManagerError, KeychainManagerError.addFailed)
    }
  }
}

final class RealmKeyManagementTests: XCTestCase {
  
  func testReturnsExistingKey() throws {
    let keychain = MockKeychainManager()
    let existing = try KeyGenerator().Generate()
    keychain.key = existing
    
    let key = try RealmKeyManagement(keychainManager: keychain).generateOrGetKey()
    
    XCTAssertEqual(key, existing)
    XCTAssertEqual(keychain.addCalledCount, 0)
  }
  
  func testCreatesKeyWhenNoneFound() throws {
    let keychain = MockKeychainManager()
    
    let key = try RealmKeyManagement(keychainManager: keychain).generateOrGetKey()
    
    XCTAssertEqual(key.count, 64)
    XCTAssertEqual(keychain.key, key)
    XCTAssertEqual(keychain.addCalledCount, 1)
  }
  
  // eg. the user pressed Deny on the Keychain prompt. The stored key must stay as it is
  func testThrowsWithoutReplacingKeyWhenReadFails() throws {
    let keychain = MockKeychainManager()
    let existing = try KeyGenerator().Generate()
    keychain.key = existing
    keychain.readThrowsError = KeychainManagerError.unhandledError(status: errSecAuthFailed)
    
    XCTAssertThrowsError(try RealmKeyManagement(keychainManager: keychain).generateOrGetKey()) { error in
      XCTAssertEqual(error as? KeychainManagerError, KeychainManagerError.unhandledError(status: errSecAuthFailed))
    }
    XCTAssertEqual(keychain.addCalledCount, 0)
    XCTAssertEqual(keychain.key, existing)
  }
  
  func testThrowsWhenNewKeyIsNotStored() throws {
    let keychain = MockKeychainManager()
    keychain.addThrowsError = KeychainManagerError.addFailed
    
    XCTAssertThrowsError(try RealmKeyManagement(keychainManager: keychain).generateOrGetKey()) { error in
      XCTAssertEqual(error as? KeychainManagerError, KeychainManagerError.addFailed)
    }
  }
}
