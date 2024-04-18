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
  }
  
  @MainActor
  public func getRealm(retry: Bool = false,
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
      
      // Realm has failed to open, potentially due to the encryption key
      // or maybe an issue with the filesystem
      // re-try, then continue with in memory database
      
      // TODO
      // Need to inform the user. This is unlikely to happen unless the keychain gets tampered with
      // and then you cannot open the realm database
      
      print(error)
      
      if !retry {
        
        // We could delete the database and re-attempt
        print("Deleting database")
        try? RealmUtilities.deleteRealmDatabase()
        
        // Give it a second incase there is a system fault
        sleep(1)
        return getRealm(retry: true)
     
      }
      
      // Finally return in memory realm instance
      config = getRealmConfigInMemory()
      RealmManager.realmInstance = try? Realm(configuration: config)
      return RealmManager.realmInstance
      
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
