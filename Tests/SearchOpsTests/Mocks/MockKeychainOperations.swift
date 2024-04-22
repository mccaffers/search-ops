// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SearchOps

public class MockKeychainOperationsNotFound : KeychainOperationsProtocol {
  public func SecItemDelete(query: [String : Any]) throws -> Bool {
    throw KeychainManagerError.noItemFound
  }
  
  public func SecItemCopyMatching(query: [String : Any]) throws -> Data {
    throw KeychainManagerError.noItemFound
  }
  
  public func SecItemAdd(query: [String : Any]) throws -> Bool {
    throw KeychainManagerError.noItemFound
  }
}

public class MockKeychainOperationsUnexpected : KeychainOperationsProtocol {
  public func SecItemCopyMatching(query: [String : Any]) throws -> Data {
    throw KeychainManagerError.unexpectedData
  }
  
  public func SecItemAdd(query: [String : Any]) throws -> Bool {
    throw KeychainManagerError.unexpectedData
  }
  public func SecItemDelete(query: [String : Any]) throws -> Bool {
    throw KeychainManagerError.unexpectedData
  }
}

public class MockKeychainOperationsUnhandledError : KeychainOperationsProtocol {
  public func SecItemCopyMatching(query: [String : Any]) throws -> Data {
    throw KeychainManagerError.unhandledError(status: 1)
  }
  
  public func SecItemAdd(query: [String : Any]) throws -> Bool {
    throw KeychainManagerError.unhandledError(status: 1)
  }
  public func SecItemDelete(query: [String : Any]) throws -> Bool {
    throw KeychainManagerError.unhandledError(status: 1)
  }
}


public class MockKeychainOperationsValidResponse: KeychainOperationsProtocol {
  public func SecItemCopyMatching(query: [String : Any]) throws -> Data {
    return try! KeyGenerator().Generate()
  }
  
  public func SecItemAdd(query: [String : Any]) throws -> Bool {
    return true
  }
  public func SecItemDelete(query: [String : Any]) throws -> Bool {
    return true
  }
}

