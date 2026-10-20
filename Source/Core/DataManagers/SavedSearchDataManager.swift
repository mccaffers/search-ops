// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// Reads and writes saved searches. Callers only ever get `SavedSearch` values, never live Realm objects.
/// Deleting a search also takes it off every dashboard.
@MainActor
public class SavedSearchDataManager {

  private let realmProvider: @MainActor () -> Realm?

  public init(realmProvider: @escaping @MainActor () -> Realm? = { RealmManager().getRealm() }) {
    self.realmProvider = realmProvider
  }

  // MARK: - Reading

  /// Every saved search, newest first
  public func all() -> [SavedSearch] {
    guard let realm = realmProvider() else { return [] }
    return realm.objects(RealmSavedSearch.self)
      .sorted(byKeyPath: "savedDate", ascending: false)
      .map { $0.eject() }
  }

  public func search(id: UUID) -> SavedSearch? {
    guard let realm = realmProvider() else { return nil }
    return realm.object(ofType: RealmSavedSearch.self, forPrimaryKey: id)?.eject()
  }

  // MARK: - Writing

  @discardableResult
  public func save(_ draft: SavedSearch) throws -> SavedSearch {
    guard let realm = realmProvider() else { throw SavedDocumentError.storageUnavailable }
    var search = draft
    search.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
    let object = RealmSavedSearch(search: search)
    try realm.write {
      realm.add(object)
    }
    return object.eject()
  }

  /// Replaces what a saved search searches for with `search`, keeping its name and when it was first saved
  @discardableResult
  public func update(id: UUID, with search: SavedSearch, now: Date = Date.now) throws -> SavedSearch {
    guard let realm = realmProvider() else { throw SavedDocumentError.storageUnavailable }
    guard let object = realm.object(ofType: RealmSavedSearch.self, forPrimaryKey: id) else {
      throw SavedDocumentError.notFound
    }
    try realm.write {
      object.apply(search)
      object.updatedDate = now
    }
    return object.eject()
  }

  /// Changes the title. An empty title shows the summary of the search again.
  @discardableResult
  public func rename(id: UUID, title: String) throws -> SavedSearch {
    guard let realm = realmProvider() else { throw SavedDocumentError.storageUnavailable }
    guard let object = realm.object(ofType: RealmSavedSearch.self, forPrimaryKey: id) else {
      throw SavedDocumentError.notFound
    }
    try realm.write {
      object.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return object.eject()
  }

  public func delete(id: UUID) {
    guard let realm = realmProvider(),
          let object = realm.object(ofType: RealmSavedSearch.self, forPrimaryKey: id) else { return }
    try? realm.write {
      realm.delete(object)
      DashboardDataManager.removePanels(in: realm) { $0 == id }
    }
  }

  /// Removes the saved searchs with these ids in one write, eg. the ones ticked in the Saved tab
  public func delete(ids: Set<UUID>) {
    guard !ids.isEmpty, let realm = realmProvider() else { return }
    let objects = realm.objects(RealmSavedSearch.self).where { $0.id.in(Array(ids)) }
    guard !objects.isEmpty else { return }
    try? realm.write {
      realm.delete(objects)
      DashboardDataManager.removePanels(in: realm) { ids.contains($0) }
    }
  }

  /// Removes every saved search, eg. from Clear All in the Saved tab
  public func deleteAll() {
    guard let realm = realmProvider() else { return }
    let objects = realm.objects(RealmSavedSearch.self)
    guard !objects.isEmpty else { return }
    try? realm.write {
      realm.delete(objects)
      DashboardDataManager.removePanels(in: realm) { _ in true }
    }
  }

  /// Removes every saved search for a host, eg. when the host is deleted
  public func deleteByHost(id: UUID) {
    guard let realm = realmProvider() else { return }
    let objects = realm.objects(RealmSavedSearch.self).where { $0.hostId == id }
    guard !objects.isEmpty else { return }
    // Read before deleting, the objects are invalidated afterwards
    let ids = Set(objects.map(\.id))
    try? realm.write {
      realm.delete(objects)
      DashboardDataManager.removePanels(in: realm) { ids.contains($0) }
    }
  }

  /// Removes saved searches whose host no longer exists. Returns how many were removed.
  @discardableResult
  public func pruneOrphans(validHostIds: Set<UUID>) -> Int {
    guard let realm = realmProvider() else { return 0 }
    let orphans = Array(realm.objects(RealmSavedSearch.self).filter { !validHostIds.contains($0.hostId) })
    guard !orphans.isEmpty else { return 0 }
    // Read before deleting, the objects are invalidated afterwards
    let count = orphans.count
    let ids = Set(orphans.map(\.id))
    do {
      try realm.write {
        realm.delete(orphans)
        DashboardDataManager.removePanels(in: realm) { ids.contains($0) }
      }
    } catch {
      return 0
    }
    return count
  }
}
