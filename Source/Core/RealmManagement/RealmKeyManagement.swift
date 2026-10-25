// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public protocol RealmKeyManagementProtocol {
  func generateOrGetKey() throws -> Data
}

public class RealmKeyManagement : RealmKeyManagementProtocol {
  
  private let keychainManager: KeychainManagerProtocol
  
  public init(keychainManager: KeychainManagerProtocol = KeychainManager()) {
    self.keychainManager = keychainManager
  }
  
  // Retrieve the existing encryption key for the app if it exists or create a new one
  // Throws when there is no key Realm can safely use, eg. the user denied the Keychain prompt
  // or a new key couldn't be stored. Never replace a key we failed to read, the realm on disk needs it
  public func generateOrGetKey() throws -> Data {
    
    do {
      let key = try keychainManager.read()
      // Success! Realm key exists in the keychain, lets return the key
      SystemLogger().message("Found an encryption key in the Keychain")
      return key
    } catch KeychainManagerError.noItemFound {
      SystemLogger().message("No encryption key found in Keychain")
    } catch let error {
      SystemLogger().message("Couldn't read the encryption key from the Keychain: \(error)", level: .fatal)
      throw error
    }
    
    // If not, lets generate a key and add it to the keychain
    // KeyGenerator can throw, and add throws when the Keychain doesn't store the key
    guard let key = try keychainManager.add(input: nil) else {
      throw KeychainManagerError.addFailed
    }
    return key
  }
 
}
