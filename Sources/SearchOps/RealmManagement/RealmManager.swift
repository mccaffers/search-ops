// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public class RealmManager : RealmManagerProtocol {
  
  private static let schemaVersion : UInt64 = 2
  
  private let realmClient: RealmClientProtocol
  
  // Enable the injection a different realm client for testing
  public init(realmClient: RealmClientProtocol = RealmClient()) {
      self.realmClient = realmClient
  }
  
  @MainActor
  private static var realmInstance: Realm?
    
  private func getRealmConfig() -> Realm.Configuration {
    
    do {
      return try Realm.Configuration(encryptionKey: RealmKeyManagement.generateOrGetKey(), schemaVersion: RealmManager.schemaVersion)
    } catch let error {
      print(error)
      return Realm.Configuration(schemaVersion: RealmManager.schemaVersion)
    }
    
  }
  
  private func getRealmConfigInMemory() -> Realm.Configuration {
    return Realm.Configuration(inMemoryIdentifier: UUID().uuidString,
                               schemaVersion: RealmManager.schemaVersion)
  }
  
  @MainActor
  public func clearRealmInstance() {
    RealmManager.realmInstance = nil
    try? RealmUtilities.deleteRealmDatabase()
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
      config = getRealmConfigInMemory()
    } else {
      config = getRealmConfig()
    }
    
    print("Attemping to load realm instance")
    
    do {
      
      // Open the realm with the configuration
      RealmManager.realmInstance = try realmClient.getRealm(config: config)
      
    } catch let error as NSError {
      
      // Realm has failed to open
      // We'll retry incase it's a temporary issue (eg. file system read)
      // However, if it's something worse, like the Key has become corrupt or is invalid
      // We'll need to load an in memory realm, and delete the existing realm database
      
      print(error)
      
      if retry == 0 {
        print("First retry, attempting again, after 1 second sleep")
        // Give it a second incase there is a system fault
        sleep(1)
        return getRealm(retry: 1)
      }
      
      // Option here, need to check the error message
      // if it's an encryption issue, we're goign to have to delete the file
      // if it's a read file issue, load in memory, and warn the user (to potentially restart the app)
      
      if retry == 1 {
        // At this point we need to inform the user
        // and check if there is a realm database on disk
        print("Second retry, lets load an in memory realm database")
        return getRealm(retry: 2, inMemory:true)
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
      catch (let error) {
        print("FileManager Error: \(error)")
      }
    }
    
    return 0.0
  }
}
