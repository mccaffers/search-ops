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
  public static func RetrieveLegacyKeychain() -> Data? {
    
    let query: [NSString: AnyObject] = [
      kSecClass: kSecClassKey,
      kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
      kSecAttrKeySizeInBits: 512 as AnyObject,
      kSecReturnData: true as AnyObject
    ]
    
    // To avoid Swift optimization bug, should use withUnsafeMutablePointer() function to retrieve the keychain item
    // See http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328#27721328
    var dataTypeRef: AnyObject?
    let status = withUnsafeMutablePointer(to: &dataTypeRef) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }
    if status == errSecSuccess {
      return dataTypeRef as? Data
    }
    
    return nil;
  }
  
  public static func DeleteLegacyKeychain() {
  
    let query: [NSString: AnyObject] = [
      kSecClass: kSecClassKey,
      kSecAttrApplicationTag: keychainIdentifierData as AnyObject
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    
    if status == errSecSuccess {
      print("successly deleted")
    } else {
      print("error deleting")
    }
  }
  
}
