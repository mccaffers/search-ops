// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public class KeychainOperations : KeychainOperationsProtocol {
  
  public init(){}
  
  public func SecItemCopyMatching(query:[String : Any]) throws -> Data {
    var item: AnyObject? = nil
    let status: OSStatus = Security.SecItemCopyMatching(query as CFDictionary, &item)
    
    // Check the return status and throw an error if appropriate.
    guard status != errSecItemNotFound else {
      throw KeychainManagerError.noItemFound
    }
    
    guard status == noErr else {
      throw KeychainManagerError.unhandledError(status: status)
    }
    
    // Parse the string value from the query result.
    guard let existingItem = item as? [String: AnyObject],
          let data = existingItem[kSecValueData as String] as? Data else {
      throw KeychainManagerError.unexpectedData
    }
      
    return data
  }
  
  public func SecItemAdd(query:[String:Any]) throws -> Bool {
    let status = Security.SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      return false
    }
    return true
  }
}
