// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

// Manages Keychain operations across iOS and macOS
public class KeychainManager {

  private static let applicationIdentifier = "searchops.app"
  private static let keychainIdentifer = "realm.key"
  
  public static func QueryKeychainMacOS() -> Data? {
    
    let query = [kSecClass as String            : kSecClassGenericPassword as String,
                 kSecAttrService as String      : "searchops",
                 kSecAttrAccount as String      : "realm",
                 kSecReturnData as String       : kCFBooleanTrue!,
                 kSecReturnAttributes as String : kCFBooleanTrue!,
                 kSecMatchLimit as String       : kSecMatchLimitOne] as [String : Any]
    
    var item: AnyObject? = nil
    let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &item)
    
    if status == noErr {
      let existingItem = item as? [String: Any]
      let passwordData = existingItem![String(kSecValueData)] as? Data
      return passwordData
    }
    
    print("Issue with querying Keychain")
    print(status)
    
    return nil
  }
  
  public static func GenerateKey() throws -> Data {
    
    var key = Data(count: 64)
    
    try key.withUnsafeMutableBytes({ (pointer: UnsafeMutableRawBufferPointer) in
      // Generates a random encryption key
      let result = SecRandomCopyBytes(kSecRandomDefault, 64, pointer.baseAddress!)
      
      if result != 0 {
        throw MyError.runtimeError("Failed to get random bytes")
      }
      assert(result == 0, "Failed to get random bytes")
    })

#if DEBUG
    print(key.map { String(format: "%02x", $0) }.joined())
#endif
    
    return key
    
  }
    
  @discardableResult
  public static func AddToKeychain(input:Data? = nil) throws -> Data {
    
    var key = input
    if (key == nil){
      print("key is empty, generating")
      key = try GenerateKey()
    }
    
    // Add the private key to the keychain
    do {
      
      let query : [String : Any] = [
        kSecClass as String        : kSecClassGenericPassword as String,
        kSecAttrService as String  : "searchops",
        kSecAttrAccount as String  : "realm",
        kSecValueData as String    : key as AnyObject]
      
      
      let status = SecItemAdd(query as CFDictionary, nil)
      print(status)
      guard status == errSecSuccess else { throw MyError.runtimeError(String(status)) }
    }
    
    return key!
    
  }
  
  
  public static func DeleteKeychainMacos() throws {
    
  
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
