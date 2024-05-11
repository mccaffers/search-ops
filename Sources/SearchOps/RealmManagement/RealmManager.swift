// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13, *)
public class RealmManager : RealmManagerProtocol {
  
  public static let schemaVersion : UInt64 = 3
  
  private let realmClient: RealmClientProtocol
  private let realmUtilities: RealmUtilitiesProtocol
  
  // Enable the injection a different realm client for testing
  public init(realmClient: RealmClientProtocol = RealmClient(),
              realmUtilities: RealmUtilitiesProtocol = RealmUtilities()) {
    self.realmClient = realmClient
    self.realmUtilities = realmUtilities
  }
  
  @MainActor
  private static var realmInstance: Realm?
    
  private func getRealmConfig() -> Realm.Configuration {
    
    do {
      return try Realm.Configuration(encryptionKey: RealmKeyManagement.generateOrGetKey(), schemaVersion: RealmManager.schemaVersion)
    } catch _ {
      SystemLogger().message("Error loading realm confg with encryption key", level:.fatal)
      
      return Realm.Configuration(schemaVersion: RealmManager.schemaVersion,
                                 migrationBlock: { migration, oldSchemaVersion in
        if oldSchemaVersion < 3 {
          migration.enumerateObjects(ofType: LogFilter.className()) { oldObject, newObject in
            // Append price value to new prices list
            newObject!["dateField"] = oldObject!["dateField"] as! RealmSquashedFieldsArray
          }
          migration.enumerateObjects(ofType: RealmFilterObject.className()) { oldObject, newObject in
            // Append price value to new prices list
            newObject!["dateField"] = oldObject!["dateField"] as! RealmSquashedFieldsArray
          }
          
        }
      })
    }
  }
  
  private func getRealmConfigInMemory() -> Realm.Configuration {
    return Realm.Configuration(inMemoryIdentifier: UUID().uuidString,
                               schemaVersion: RealmManager.schemaVersion)
  }
  
  @MainActor
  public func clearRealmInstance() {
    RealmManager.realmInstance = nil
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
    if inMemory {
      SystemLogger().message("Loading in memory instance without encryption", level: .warn)
      config = getRealmConfigInMemory()
    } else {
      config = getRealmConfig()
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
