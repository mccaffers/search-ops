// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

final class KeychainOperationTests: XCTestCase {
  
  func testKeychainOperationsNotFound() throws {
    let keychainOps = MockKeychainOperationsNotFound()
    
    let query = [kSecClass as String: kSecClassGenericPassword as String]
    as [String : Any]
    
    XCTAssertThrowsError(try keychainOps.SecItemCopyMatching(query: query)) { error in
      XCTAssertEqual(error as! KeychainManagerError,  KeychainManagerError.noItemFound)
    }
  }
  
  func testKeychainOperationsUnpexected() throws {
    let keychainOps = MockKeychainOperationsUnexpected()
    
    let query = [kSecClass as String: kSecClassGenericPassword as String]
    as [String : Any]
    
    XCTAssertThrowsError(try keychainOps.SecItemCopyMatching(query: query)) { error in
      XCTAssertEqual(error as! KeychainManagerError,  KeychainManagerError.unexpectedData)
    }
  }
  
  func testKeychainOperationsUnhandled() throws {
    let keychainOps = MockKeychainOperationsUnhandledError()
    
    let query = [kSecClass as String: kSecClassGenericPassword as String]
    as [String : Any]
    
    XCTAssertThrowsError(try keychainOps.SecItemCopyMatching(query: query)) { error in
      XCTAssertEqual(error as! KeychainManagerError,  KeychainManagerError.unhandledError(status: 1))
    }
  }
  
}




