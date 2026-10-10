// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// Reads and writes data views. Callers only ever get `DataView` values, never live Realm objects.
@MainActor
public class DataViewDataManager {

  private let realmProvider: @MainActor () -> Realm?

  public init(realmProvider: @escaping @MainActor () -> Realm? = { RealmManager().getRealm() }) {
    self.realmProvider = realmProvider
  }

  // MARK: - Reading

  /// A host's data views, sorted by name
  public func views(hostId: UUID) -> [DataView] {
    guard let realm = realmProvider() else { return [] }
    return realm.objects(RealmDataView.self)
      .where { $0.hostId == hostId }
      .map { $0.eject() }
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  public func view(id: UUID) -> DataView? {
    guard let realm = realmProvider() else { return nil }
    return realm.object(ofType: RealmDataView.self, forPrimaryKey: id)?.eject()
  }

  // MARK: - Validation

  /// nil when the view can be saved. Names are unique per host, ignoring case; patterns may repeat.
  public func validate(_ view: DataView) -> DataViewError? {
    let normalized = view.normalized()
    if normalized.name.isEmpty {
      return .nameEmpty
    }
    let nameTaken = views(hostId: normalized.hostId).contains {
      $0.id != normalized.id && $0.name.caseInsensitiveCompare(normalized.name) == .orderedSame
    }
    if nameTaken {
      return .nameTaken
    }
    return DataViewPattern.validate(normalized.pattern)
  }

  // MARK: - Writing

  @discardableResult
  public func create(_ draft: DataView) throws -> DataView {
    if let error = validate(draft) {
      throw error
    }
    guard let realm = realmProvider() else { throw DataViewError.storageUnavailable }

    var view = draft.normalized()
    view.createdDate = Date.now
    view.updatedDate = view.createdDate
    let object = RealmDataView(view: view)
    try realm.write {
      realm.add(object)
    }
    return object.eject()
  }

  @discardableResult
  public func update(_ view: DataView) throws -> DataView {
    if let error = validate(view) {
      throw error
    }
    guard let realm = realmProvider() else { throw DataViewError.storageUnavailable }
    guard let object = realm.object(ofType: RealmDataView.self, forPrimaryKey: view.id) else {
      throw DataViewError.notFound
    }

    var updated = view.normalized()
    updated.updatedDate = Date.now
    try realm.write {
      object.apply(updated)
    }
    return object.eject()
  }

  public func delete(id: UUID) {
    guard let realm = realmProvider(),
          let object = realm.object(ofType: RealmDataView.self, forPrimaryKey: id) else { return }
    try? realm.write {
      realm.delete(object)
    }
  }

  /// Removes every data view for a host, eg. when the host is deleted
  public func deleteByHost(id: UUID) {
    guard let realm = realmProvider() else { return }
    let objects = realm.objects(RealmDataView.self).where { $0.hostId == id }
    guard !objects.isEmpty else { return }
    try? realm.write {
      realm.delete(objects)
    }
  }

  /// Removes data views whose host no longer exists. Returns how many were removed.
  @discardableResult
  public func pruneOrphans(validHostIds: Set<UUID>) -> Int {
    guard let realm = realmProvider() else { return 0 }
    let orphans = Array(realm.objects(RealmDataView.self).filter { !validHostIds.contains($0.hostId) })
    guard !orphans.isEmpty else { return 0 }
    // Count before deleting, the objects are invalidated afterwards
    let count = orphans.count
    do {
      try realm.write {
        realm.delete(orphans)
      }
    } catch {
      return 0
    }
    return count
  }
}
