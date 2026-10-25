// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13, *)
public class RealmManager : RealmManagerProtocol {
  
  // 8: RealmDataView and RealmFieldLabel. New classes only, so the migration block needs nothing
  // 9: LogEvent source and truncated flags. Empty and false are right for older events, so nothing to migrate
  // 10: RealmSearchEvent field filters. Older searches had none, so the empty list needs nothing
  // 11: RealmSavedDocument. A new class only, so the migration block needs nothing
  // 12: RealmSavedSearch. A new class only, so the migration block needs nothing
  // 13: RealmSavedSearch updated date. Optional, so nil is right for older searches
  // 14: RealmSavedSearch column widths. Older searches had none, so the empty list needs nothing
  // 15: RealmSavedSearch relative periods and now flags. Empty and false read as the fixed dates older searches had
  // 16: RealmDashboard and its embedded RealmDashboardPanel. New classes only, so the migration block needs nothing
  // 17: RealmDashboardPanel grid frames. Zero widths read as the old width, height and column count, so nothing to migrate
  // 18: RealmDashboardPanel column widths. Older panels had none, so the empty list needs nothing
  public static let schemaVersion : UInt64 = 18
  
  // Debug builds only: launching with SEARCHOPS_IN_MEMORY_STORE=1 keeps the database in memory,
  // so the app never reads the encryption key from the Keychain or writes a realm file.
  // Unsigned dev builds can then run without a Keychain prompt, and nothing entered outlives the app
  public static let inMemoryStoreVariable = "SEARCHOPS_IN_MEMORY_STORE"

  private let realmClient: RealmClientProtocol
  private let realmUtilities: RealmUtilitiesProtocol
  private let keyManagement: RealmKeyManagementProtocol
  private let environment: [String: String]

  // Enable the injection a different realm client for testing
  public init(realmClient: RealmClientProtocol = RealmClient(),
              realmUtilities: RealmUtilitiesProtocol = RealmUtilities(),
              keyManagement: RealmKeyManagementProtocol = RealmKeyManagement(),
              environment: [String: String] = ProcessInfo.processInfo.environment) {
    self.realmClient = realmClient
    self.realmUtilities = realmUtilities
    self.keyManagement = keyManagement
    self.environment = environment
  }

  var inMemoryStoreRequested: Bool {
#if DEBUG
    return environment[RealmManager.inMemoryStoreVariable] == "1"
#else
    return false
#endif
  }
  
  @MainActor
  private static var realmInstance: Realm?
  
  // True when the encryption key couldn't be read and this launch runs on an in-memory realm,
  // so the root views can tell the user their data isn't loaded and nothing will be saved
  @MainActor
  public private(set) static var keyUnavailable = false
    
  static let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
      if oldSchemaVersion < 3 {
          migration.enumerateObjects(ofType: LogFilter.className()) { oldObject, newObject in
              newObject!["dateField"] = oldObject!["dateField"] as! RealmSquashedFieldsArray
          }
          migration.enumerateObjects(ofType: RealmFilterObject.className()) { oldObject, newObject in
              newObject!["dateField"] = oldObject!["dateField"] as! RealmSquashedFieldsArray
          }
      }
      if oldSchemaVersion < 7 {
          // New columns start empty, not at the Swift default, and "" isn't
          // an AWSService, so reading it would crash. The AWS strings can stay empty.
          migration.enumerateObjects(ofType: HostDetails.className()) { _, newObject in
              newObject?["awsService"] = AWSService.es.rawValue
          }
      }
  }
    
  // Throws when there is no encryption key to open the realm on disk with
  private func getRealmConfig() throws -> Realm.Configuration {
      return try Realm.Configuration(
          encryptionKey: keyManagement.generateOrGetKey(),
          schemaVersion: RealmManager.schemaVersion,
          migrationBlock: RealmManager.migrationBlock
      )
  }
  
  private func getRealmConfigInMemory() -> Realm.Configuration {
    return Realm.Configuration(inMemoryIdentifier: UUID().uuidString,
                               schemaVersion: RealmManager.schemaVersion)
  }
  
  @MainActor
  public func clearRealmInstance() {
    RealmManager.realmInstance = nil
    RealmManager.keyUnavailable = false
    try? realmUtilities.deleteRealmDatabase()
  }
  
  @MainActor
  public func getRealm(retry: Int = 0,
                       inMemory: Bool = false) -> Realm? {
    
    var config: Realm.Configuration
    
    if let realmInstance = RealmManager.realmInstance {
      return realmInstance
    }
    
    // Use the getKey() function to get the stored encryption key or create a new one
    if inMemory || inMemoryStoreRequested {
      SystemLogger().message("Loading in memory instance without encryption", level: .warn)
      config = getRealmConfigInMemory()
    } else {
      do {
        config = try getRealmConfig()
      } catch {
        // Without the key the realm on disk can't be opened, and must not be deleted:
        // the key may still be in the Keychain (eg. the user denied the prompt this time).
        // Run in memory for this launch instead, the file stays as it is for the next one
        SystemLogger().message("No encryption key available, loading an in memory realm database. Nothing will be saved until the app can read the key from the Keychain", level: .fatal)
        RealmManager.keyUnavailable = true
        config = getRealmConfigInMemory()
      }
    }
    


    
    do {
      // Open the realm with the configuration
      RealmManager.realmInstance = try realmClient.getRealm(config: config)
      SystemLogger().message("Successfully opened realm instance")
    } catch let error as NSError {
      
      // Realm has failed to open
      // We'll retry incase it's a temporary issue (eg. file system read)
      // However, if it's something worse, like the Key has become corrupt or is invalid
      // We'll need to load an in memory realm, and delete the existing realm database
      print(error)
      
      if retry == 0 {
        SystemLogger().message("Failed to open realm database. Retrying...", level: .warn)
        // Give it a second incase there is a system fault
        sleep(1)
        return getRealm(retry: 1)
      }
      
      // Option here, need to check the error message
      // if it's an encryption issue, we're goign to have to delete the file
      // if it's a read file issue, load in memory, and warn the user (to potentially restart the app)
      
      if retry == 1 {
        var errorsToCheck = error.userInfo.filter {$0.key == "Error Name" || $0.key == "RLMErrorCodeNameKey"}
        if errorsToCheck.count > 0 {
          if errorsToCheck.contains(where: {$0.value as? String == "InvalidEncryptionKey" ||
                                      $0.value as? String == "InvalidDatabase"}) {
            
            do {
              print("InvalidEncryptionKey / InvalidDatabase error, we're going to have to delete the realm database")
              clearRealmInstance()
              getRealm(retry: 2)
            } catch let error {
              print(error)
              // FATAL Issue
              // Can't open the realm database, and can't delete it
              // Fall back to in memory realm database for the moment so the app can run
              SystemLogger().message("Loading realm on disk failed, failed to delete, this shouldn't occur. Loading in memory Realm database. You may need to reinstall the app.", level:.warn)
              return getRealm(retry: 2, inMemory:true)
            }
            
          }
        }

          
          
        
      } else {
        // Encryption key failed, delete was successful
        //
        SystemLogger().message("Encryption key failed, delete was successful but there was still an error, loading in memory realm database", level:.warn)
        return getRealm(retry: 2, inMemory: true)
      }
      
    }
    
    return RealmManager.realmInstance
    
  }
  
  public static func checkRealmFileSize() -> Double {
    
    if let realmPath = Realm.Configuration.defaultConfiguration.fileURL?.relativePath {
      do {
        let attributes = try FileManager.default.attributesOfItem(atPath:realmPath)
        if let fileSize = attributes[FileAttributeKey.size] as? Double {
          
          return fileSize / 1000000.0
        }
      }
      catch _ {
        SystemLogger().message("FileManager Error", level:.fatal)
      }
    }
    
    return 0.0
  }
}
