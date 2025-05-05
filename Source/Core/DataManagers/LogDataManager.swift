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
@MainActor
public class LogDataManager: ObservableObject {
  
  @Published
  public var items: [LogEvent] = []
  
  public init() {
    self.items = readServer()
  }
  
  public func refresh() {
    self.items = readServer()
  }
  
  
  private func readServer() -> [LogEvent] {
    
    if let realm = RealmManager().getRealm() {
      let realmArrayObject = realm.objects(LogEvent.self)
      return Array(realmArrayObject)
    } else {
      return []
    }
  }
  
  public func addNew(item: LogEvent) {
    addNewLogEntry(item: item);
    rotateLogs()
  }
  
  private func addNewLogEntry(item: LogEvent) {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        realm.add(item, update: Realm.UpdatePolicy.modified)
      }
    }
  }
  
  
  private func rotateLogs() {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        let realmArrayObject = realm.objects(LogEvent.self)
        let myArray = Array(realmArrayObject)
        let limit = (myArray.count - 20)
        if limit > 1,
           let oldest = myArray.sorted(by: { $0.date < $1.date }).first {
          realm.delete(oldest)
        }
      }
    }
  }
  
  
  public func deleteAll(){
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        let allUploadingObjects = realm.objects(LogEvent.self)
        realm.delete(allUploadingObjects)
      }
    }
    refresh()
  }
}

