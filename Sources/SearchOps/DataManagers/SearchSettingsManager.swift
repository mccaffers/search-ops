// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import Foundation
import RealmSwift

@available(iOS 15, *)
public class ApplicationSettings : Object {

	@Persisted(primaryKey: true) public var id: UUID = UUID()
	
	// Search Settings
	@Persisted public var maximumDocumentsPerPage : Int = 25
	@Persisted public var requestTimeout : Int = 15

}

@available(macOS 13.0, *)
@available(iOS 15.0, *)
public class SettingsDatatManager: ObservableObject {
  
  @Published
  public var settings: ApplicationSettings? = nil
  
  @MainActor
  public init() {
    self.settings = ReadServer()
  }
  
  @MainActor 
  public func setDocumentsPerPage(input: Int) {
    if let realm = RealmManager().getRealm() {
      try! realm.write {
        self.settings?.maximumDocumentsPerPage = input
      }
    }
  }
  
  @MainActor
  public func setTimeoiut(input: Int) {
    if let realm = RealmManager().getRealm() {
      try! realm.write {
        self.settings?.requestTimeout = input
      }
    }
  }
  
  @MainActor
  private func ReadServer() -> ApplicationSettings? {
    
    if let realm = RealmManager().getRealm() {
      let settingsObj = realm.objects(ApplicationSettings.self)
      if settingsObj.count == 1 {
        return settingsObj.first
      } else {
        let initialSettings = ApplicationSettings()
        Update(item:initialSettings)
        return initialSettings
      }
    } else {
      return nil
    }
  }
  
  @MainActor
  private func Update(item: ApplicationSettings) {
    if let realm = RealmManager().getRealm() {
      try! realm.write {
        realm.add(item, update: Realm.UpdatePolicy.modified)
      }
    }
  }
}
