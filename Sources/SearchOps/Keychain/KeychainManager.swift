// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

// Manages Keychain operations across iOS and macOS
// KeychainManager -> KeychainOperations -> Foundation.Security
public class KeychainManager {

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
  public func Query() -> Data? {
    
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
  public func Add(input:Data? = nil) throws -> Data? {
    
    var key = input
    if (key == nil){
      print("key is empty, generating")
      key = try keyGenerator.Generate()
    }
    
    let query : [String : Any] = [
      kSecClass as String        : kSecClassGenericPassword as String,
      kSecAttrService as String  : "searchops",
      kSecAttrAccount as String  : "realm",
      kSecValueData as String    : key as AnyObject]
    
    
    do {
      let response = try keychainOps.SecItemAdd(query: query)
      if response {
        return key!
      }
    } catch _ {
      return nil
    }
    
    return key!
    
  }
  
  
  public func Delete() throws {
    
    // Add the private key to the keychain
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
