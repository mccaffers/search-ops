// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

// Manages Keychain operations across iOS and macOS
// KeychainManager -> KeychainOperations -> Foundation.Security
public class KeychainManager : KeychainManagerProtocol {

  private static let applicationIdentifier = "searchops.app"
  private static let keychainIdentifer = "realm.key"
  
  private let keychainOps: KeychainOperationsProtocol
  private let keyGenerator: KeyGeneratorProtocol
   
  public init(keychainOps: KeychainOperationsProtocol = KeychainOperations(),
              keyGenerator: KeyGeneratorProtocol = KeyGenerator()) {
      self.keychainOps = keychainOps
      self.keyGenerator = keyGenerator
  }
  
  // Builds the query for the Keychain operations
  public func query() -> Data? {
    
    let query = [kSecClass as String            : kSecClassGenericPassword as String,
                 kSecAttrService as String      : "searchops",
                 kSecAttrAccount as String      : "realm",
                 kSecReturnData as String       : kCFBooleanTrue!,
                 kSecReturnAttributes as String : kCFBooleanTrue!,
                 kSecMatchLimit as String       : kSecMatchLimitOne] as [String : Any]
    
    do {
      return try keychainOps.SecItemCopyMatching(query: query)
    } catch _ {
      return nil
    }
  }
      
  // Builds the query for the Keychain operations
  @discardableResult
  public func add(input:Data? = nil) throws -> Data? {
    
    var key = Data(count: 64)
    
    if (input == nil){
      key = try keyGenerator.Generate()
    } else {
      key = input!
    }
    
#if DEBUG
    print("Adding", key.map { String(format: "%02x", $0) }.joined())
#endif
    
    let query : [String : Any] = [
      kSecClass as String        : kSecClassGenericPassword as String,
      kSecAttrService as String  : "searchops",
      kSecAttrAccount as String  : "realm",
      kSecValueData as String    : key as AnyObject]
    
    do {
      let response = try keychainOps.SecItemAdd(query: query)
      print("Response", response)
      if response {
        return key
      }
    } catch _ {
      return nil
    }
    
    return key
    
  }
  
  public func delete() throws {
    
    do {

      let query : [String : Any] = [
                 kSecClass as String        : kSecClassGenericPassword as String,
                 kSecAttrService as String  : "searchops",
                 kSecAttrAccount as String  : "realm"]
             
    
      
      let status = SecItemDelete(query as CFDictionary)
      print(status)
      
    }
    
  }
  
}
