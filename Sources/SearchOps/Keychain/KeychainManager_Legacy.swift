// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

// When I started, I used an example from Realm Swift SDK pages
// https://www.mongodb.com/docs/realm/sdk/swift/realm-files/encrypt-a-realm/
//
// However, the documented code does not work for macOS so I have migrated the
// Keychain process to use kSecClassGenericPassword for shared use, and supportability in iOS
// and macOS. As well, I've updated the keychain identifer to reflect the application
// this can be viewed in ./KeychainManager.swift

// This code will need to remain to migrate any existing users
public class LegacyKeychainManager {
  
  private static let keychainIdentifierData = "io.Realm.EncryptionExampleKey".data(using: String.Encoding.utf8, 
                                                                                   allowLossyConversion: false)

  private let keychainOps: KeychainOperationsProtocol
   
  public init(keychainOps: KeychainOperationsProtocol = KeychainOperations()) {
     self.keychainOps = keychainOps
  }
  
  public func RetrieveLegacyKeychain() -> Data? {

    let query = [kSecClass as String              : kSecClassKey as String,
                 kSecAttrApplicationTag as String : LegacyKeychainManager.keychainIdentifierData as AnyObject,
                 kSecAttrKeySizeInBits as String  :  512 as AnyObject,
                 kSecReturnData as String         : kCFBooleanTrue!] as [String : Any]
    
    do {
      return try keychainOps.SecItemCopyMatching(query: query)
    } catch let error {
      print(error)
      return nil
    }
  }
  
  public func DeleteLegacyKeychain() {
  
    let query: [NSString: AnyObject] = [
      kSecClass: kSecClassKey,
      kSecAttrApplicationTag: LegacyKeychainManager.keychainIdentifierData as AnyObject
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    
    if status == errSecSuccess {
      print("successly deleted")
    } else {
      print("error deleting")
    }
  }
  
  public func AddLegacyKeychain() throws -> Data? {
    let key = try KeyGenerator.New()
    
    let query = [kSecClass as String              : kSecClassKey as String,
                 kSecAttrApplicationTag as String : LegacyKeychainManager.keychainIdentifierData as AnyObject,
                 kSecAttrKeySizeInBits as String  :  512 as AnyObject,
                 kSecValueData as String          : key as AnyObject] as [String : Any]
    
    do {
      let response = try keychainOps.SecItemAdd(query: query)
      if response {
        return key
      }
    } catch _ {
      return nil
    }
    
    return key
  }
  
}
