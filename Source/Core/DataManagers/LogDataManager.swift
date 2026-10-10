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

  // The number of requests kept, the oldest are deleted as new ones are added
  public static let limit = 50

  public init() {
    self.items = readServer()
  }
  
  public func refresh() {
    self.items = readServer()
  }

  /// The events still in the database, most recent first
  public var newestFirst: [LogEvent] {
    items.filter { !$0.isInvalidated }.sorted { $0.date > $1.date }
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
  
  
  // Keeps the newest `limit` events and deletes the rest
  private func rotateLogs() {
    if let realm = RealmManager().getRealm() {
      let expired = Array(realm.objects(LogEvent.self)
        .sorted(byKeyPath: "date", ascending: false)
        .dropFirst(LogDataManager.limit))
      guard !expired.isEmpty else { return }
      try? realm.write {
        LogDataManager.delete(expired, from: realm)
      }
    }
  }

  // The host details are objects of their own, not embedded, so they're deleted with their event
  private static func delete(_ events: [LogEvent], from realm: Realm) {
    let hosts = events.compactMap { $0.host }
    realm.delete(hosts.compactMap { $0.host })
    realm.delete(hosts)
    realm.delete(events)
  }
  
  
  public func deleteAll(){
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        LogDataManager.delete(Array(realm.objects(LogEvent.self)), from: realm)
      }
    }
    refresh()
  }
}

