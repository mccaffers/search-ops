// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// `RealmMigration` manages the migration of keychain storage mechanisms to enhance compatibility across different iOS and macOS versions.
public class RealmMigration {
  
  private let legacyKeychainManager: LegacyKeychainManagerProtocol
  private let keychainManager: KeychainManagerProtocol
  
  public init(legacyKeychainManager: LegacyKeychainManagerProtocol = LegacyKeychainManager(),
              keychainManager: KeychainManagerProtocol = KeychainManager() ) {
    self.legacyKeychainManager = legacyKeychainManager
    self.keychainManager = keychainManager
  }
  
  /// Checks if migration is necessary by determining the presence of legacy keychain items.
  /// - Returns: A Boolean indicating whether a legacy keychain item exists that requires migration.
  public func isMigrationNecessary() -> Bool {
    // Retrieve the legacy keychain item. This item is checked to see if it's using older keychain classes.
    let legacyKey = legacyKeychainManager.retrieveLegacyKeychain()
    return legacyKey != nil  // Returns true if there is a legacy keychain item, indicating migration is necessary.
  }
  
  /// Performs the migration if it is necessary by transferring data from a legacy keychain class to a more compatible class.
  /// - Returns: A tuple containing a boolean indicating success and an optional error if the migration fails.
  public func performMigrationIfNecessary() -> (success: Bool, error: Error?) {
    
    SystemLogger().message("Checking whether the encryption key in your Keychain need to be migrated to a new format")
    
    // First, check if there is a legacy keychain item that needs to be migrated.
    if let legacyKey = legacyKeychainManager.retrieveLegacyKeychain() {
      // Attempt to delete the old legacy keychain item to prevent duplicate data.
      
      SystemLogger().message("Found a legacy keychain entry, deleting")
      _ = legacyKeychainManager.deleteLegacyKeychain()
      
      do {
        // Attempt to add the retrieved item to the new keychain class which is more compatible across iOS and macOS.
        SystemLogger().message("Creating a new keychain entry")
        _ = try keychainManager.add(input: legacyKey)
        SystemLogger().message("Successfully migrated keychain")
      } catch let error {
        // Return false and the error if the migration process fails during the addition of the new keychain item.
        
        SystemLogger().message("Uh Oh! Sorry! Keychain migration failed")
        SystemLogger().message(error.localizedDescription)
        return (false, error)
      }
    } else {
      SystemLogger().message("No key with the old format found in the Keychain found")
    }
    
    // If there was no legacy key or the migration was successful, return true with no error.
    return (true, nil)
  }
}
