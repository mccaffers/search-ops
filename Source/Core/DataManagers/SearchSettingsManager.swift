// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13.0, *)
@available(iOS 15.0, *)
public class SettingsDataManager: ObservableObject {
  
  @Published
  public var settings: ApplicationSettings? = nil
  
  public static let defaultDocumentsPerPage = 25
  // Elasticsearch rejects requests where from + size exceeds index.max_result_window (10,000 by default)
  public static let documentsPerPageRange = 1...10_000
  // Quick picks offered next to the documents per page field, any other value is a custom one
  public static let documentsPerPagePresets = [25, 50, 100, 200]

  /// The preset matching a saved documents per page value, or nil when the value is a custom one
  public static func documentsPerPagePreset(matching value: Int) -> Int? {
    documentsPerPagePresets.contains(value) ? value : nil
  }

  /// Parses a documents per page value typed by the user, returning nil when it isn't a whole number in range
  public static func parseDocumentsPerPage(_ input: String) -> Int? {
    guard let value = Int(input.trimmingCharacters(in: .whitespaces)),
          documentsPerPageRange.contains(value) else {
      return nil
    }
    return value
  }
  
  /// The saved documents per page, or the default when no settings could be read
  public var documentsPerPage: Int {
    settings?.maximumDocumentsPerPage ?? Self.defaultDocumentsPerPage
  }
  
  @MainActor
  public init() {
    self.settings = readServer()
  }
  
  @MainActor 
  public func setDocumentsPerPage(input: Int) {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        self.settings?.maximumDocumentsPerPage = input
      }
    }
  }
  
  @MainActor
  public func setTimeoiut(input: Int) {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        self.settings?.requestTimeout = input
      }
    }
  }
  
  @MainActor
  private func readServer() -> ApplicationSettings? {
    
    if let realm = RealmManager().getRealm() {
      let settingsObj = realm.objects(ApplicationSettings.self)
      if settingsObj.count == 1 {
        return settingsObj.first
      } else {
        let initialSettings = ApplicationSettings()
        update(item:initialSettings)
        return initialSettings
      }
    } else {
      return nil
    }
  }
  
  @MainActor
  private func update(item: ApplicationSettings) {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        realm.add(item, update: Realm.UpdatePolicy.modified)
      }
    }
  }
}
