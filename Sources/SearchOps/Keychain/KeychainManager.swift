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
   
  public init(keychainOps: KeychainOperationsProtocol = KeychainOperations()) {
     self.keychainOps = keychainOps
  }
  
  // Builds the query for the Keychain operations
  public func QueryKeychainMacOS() -> Data? {
    
    let query = [kSecClass as String            : kSecClassGenericPassword as String,
                 kSecAttrService as String      : "searchops",
                 kSecAttrAccount as String      : "realm",
                 kSecReturnData as String       : kCFBooleanTrue!,
                 kSecReturnAttributes as String : kCFBooleanTrue!,
                 kSecMatchLimit as String       : kSecMatchLimitOne] as [String : Any]
    
    do {
      return try keychainOps.SecItemCopyMatching(query: query)
    } catch let error {
      print(error)
      return nil
    }
  }
      
  // Builds the query for the Keychain operations
  public func AddToKeychain(input:Data? = nil) throws -> Data? {
    
    var key = input
    if (key == nil){
      print("key is empty, generating")
      key = try KeyGenerator.New()
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
  
  
  public func DeleteKeychainMacos() throws {
    
  
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
