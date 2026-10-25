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
    guard let legacyKey = legacyKeychainManager.retrieveLegacyKeychain() else {
      SystemLogger().message("No key with the old format found in the Keychain found")
      return (true, nil)
    }
    
    SystemLogger().message("Found a legacy keychain entry")
    
    // A key in the new format is the one RealmManager already opens the realm with, so keep it.
    // The legacy entry stays too: nothing is deleted unless its key is safely stored elsewhere
    do {
      _ = try keychainManager.read()
      SystemLogger().message("A keychain entry in the new format already exists, keeping it")
      return (true, nil)
    } catch KeychainManagerError.noItemFound {
      // Nothing in the new format yet, so migrate
    } catch let error {
      // Can't tell whether a new key exists, so change nothing and try again next launch
      SystemLogger().message("Couldn't check the Keychain for a key in the new format, keychain migration will retry")
      SystemLogger().message(error.localizedDescription)
      return (false, error)
    }
    
    // Store the key in the new format before deleting the legacy entry,
    // otherwise a failed add would lose the only copy of the key
    do {
      // Attempt to add the retrieved item to the new keychain class which is more compatible across iOS and macOS.
      SystemLogger().message("Creating a new keychain entry")
      _ = try keychainManager.add(input: legacyKey)
    } catch let error {
      // Return false and the error if the migration process fails during the addition of the new keychain item.
      // The legacy entry is untouched, so the next launch can try again
      SystemLogger().message("Uh Oh! Sorry! Keychain migration failed")
      SystemLogger().message(error.localizedDescription)
      return (false, error)
    }
    
    // The key is safe in the new format, so the legacy entry can go
    SystemLogger().message("Successfully migrated keychain, deleting the legacy keychain entry")
    if !legacyKeychainManager.deleteLegacyKeychain() {
      SystemLogger().message("Couldn't delete the legacy keychain entry, the key in the new format is used either way")
    }
    
    // If there was no legacy key or the migration was successful, return true with no error.
    return (true, nil)
  }
}
