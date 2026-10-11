// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// Reads and writes saved documents. Callers only ever get `SavedDocument` values, never live Realm objects.
@MainActor
public class SavedDocumentDataManager {

  private let realmProvider: @MainActor () -> Realm?

  public init(realmProvider: @escaping @MainActor () -> Realm? = { RealmManager().getRealm() }) {
    self.realmProvider = realmProvider
  }

  // MARK: - Reading

  /// Every saved document, newest first
  public func all() -> [SavedDocument] {
    guard let realm = realmProvider() else { return [] }
    return realm.objects(RealmSavedDocument.self)
      .sorted(byKeyPath: "savedDate", ascending: false)
      .map { $0.eject() }
  }

  /// A host's saved documents, newest first
  public func documents(hostId: UUID) -> [SavedDocument] {
    guard let realm = realmProvider() else { return [] }
    return realm.objects(RealmSavedDocument.self)
      .where { $0.hostId == hostId }
      .sorted(byKeyPath: "savedDate", ascending: false)
      .map { $0.eject() }
  }

  public func document(id: UUID) -> SavedDocument? {
    guard let realm = realmProvider() else { return nil }
    return realm.object(ofType: RealmSavedDocument.self, forPrimaryKey: id)?.eject()
  }

  /// The saved copy of a document on a host, if it's been saved
  public func find(hostId: UUID, ref: DocumentRef) -> SavedDocument? {
    object(hostId: hostId, ref: ref)?.eject()
  }

  private func object(hostId: UUID, ref: DocumentRef) -> RealmSavedDocument? {
    guard let realm = realmProvider() else { return nil }
    return realm.objects(RealmSavedDocument.self)
      .where { $0.hostId == hostId && $0.docIndex == ref.index && $0.docId == ref.id }
      .first
  }

  // MARK: - Writing

  /// Saves a document, or returns the one already saved for the same host, index and id unchanged
  @discardableResult
  public func save(_ draft: SavedDocument) throws -> SavedDocument {
    guard !draft.docIndex.isEmpty, !draft.docId.isEmpty else { throw SavedDocumentError.missingReference }
    if let existing = find(hostId: draft.hostId, ref: draft.ref) {
      return existing
    }
    guard let realm = realmProvider() else { throw SavedDocumentError.storageUnavailable }

    var document = draft
    document.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
    let object = RealmSavedDocument(document: document)
    try realm.write {
      realm.add(object)
    }
    return object.eject()
  }

  /// Changes the title. An empty title shows the default `index / id` again.
  @discardableResult
  public func rename(id: UUID, title: String) throws -> SavedDocument {
    guard let realm = realmProvider() else { throw SavedDocumentError.storageUnavailable }
    guard let object = realm.object(ofType: RealmSavedDocument.self, forPrimaryKey: id) else {
      throw SavedDocumentError.notFound
    }
    try realm.write {
      object.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return object.eject()
  }

  /// Points a saved document at the index it's now in, eg. after an ILM shrink. When the document is already saved
  /// there too, that one is kept, taking this one's title if it has none, and this one is removed.
  /// Returns the saved document, or nil when it isn't saved or the database can't be written.
  @discardableResult
  public func relocate(id: UUID, to index: String) -> SavedDocument? {
    guard !index.isEmpty,
          let realm = realmProvider(),
          let moved = realm.object(ofType: RealmSavedDocument.self, forPrimaryKey: id) else { return nil }
    guard moved.docIndex != index else { return moved.eject() }
    let existing = object(hostId: moved.hostId, ref: DocumentRef(index: index, id: moved.docId))
    do {
      try realm.write {
        if let existing = existing {
          if existing.title.isEmpty {
            existing.title = moved.title
          }
          realm.delete(moved)
        } else {
          moved.docIndex = index
        }
      }
    } catch {
      return nil
    }
    return (existing ?? moved).eject()
  }

  public func delete(id: UUID) {
    guard let realm = realmProvider(),
          let object = realm.object(ofType: RealmSavedDocument.self, forPrimaryKey: id) else { return }
    try? realm.write {
      realm.delete(object)
    }
  }

  /// Unsaves a document on a host, eg. from the bookmark button in the Document panel
  public func delete(hostId: UUID, ref: DocumentRef) {
    guard let realm = realmProvider(), let object = object(hostId: hostId, ref: ref) else { return }
    try? realm.write {
      realm.delete(object)
    }
  }

  /// Removes every saved document, eg. from Clear All in the Saved tab
  public func deleteAll() {
    guard let realm = realmProvider() else { return }
    let objects = realm.objects(RealmSavedDocument.self)
    guard !objects.isEmpty else { return }
    try? realm.write {
      realm.delete(objects)
    }
  }

  /// Removes every saved document for a host, eg. when the host is deleted
  public func deleteByHost(id: UUID) {
    guard let realm = realmProvider() else { return }
    let objects = realm.objects(RealmSavedDocument.self).where { $0.hostId == id }
    guard !objects.isEmpty else { return }
    try? realm.write {
      realm.delete(objects)
    }
  }

  /// Removes saved documents whose host no longer exists. Returns how many were removed.
  @discardableResult
  public func pruneOrphans(validHostIds: Set<UUID>) -> Int {
    guard let realm = realmProvider() else { return 0 }
    let orphans = Array(realm.objects(RealmSavedDocument.self).filter { !validHostIds.contains($0.hostId) })
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
