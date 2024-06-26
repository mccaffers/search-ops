// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public protocol KeychainOperationsProtocol {
  func SecItemCopyMatching(query:[String : Any]) throws -> Data
  func SecItemAdd(query:[String:Any]) throws -> Bool
  func SecItemDelete(query:[String:Any]) throws -> Bool
}
