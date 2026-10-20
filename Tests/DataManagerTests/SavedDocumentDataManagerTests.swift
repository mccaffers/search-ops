// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import Testing
import RealmSwift

@testable import Search_Ops

@MainActor
struct SavedDocumentDataManagerTests {

  // Each test gets its own in-memory database, nothing is shared
  let realm: Realm
  let manager: SavedDocumentDataManager
  let hostId = UUID()

  init() throws {
    let realm = try Realm(configuration: Realm.Configuration(inMemoryIdentifier: UUID().uuidString,
                                                             schemaVersion: RealmManager.schemaVersion))
    self.realm = realm
    self.manager = SavedDocumentDataManager(realmProvider: { realm })
  }

  private func draft(_ docId: String,
                     index: String = "logs-2026.10.10",
                     host: UUID? = nil,
                     savedDate: Date = Date.now) -> SavedDocument {
    SavedDocument(hostId: host ?? hostId, docIndex: index, docId: docId, searchIndex: "logs-*", savedDate: savedDate)
  }

  // MARK: - Save

  @Test func saveStoresEverything() throws {
    let range = DateInterval(start: Date(timeIntervalSince1970: 1_000), end: Date(timeIntervalSince1970: 5_000))
    let dataViewId = UUID()
    var document = draft("abc")
    document.title = "  Failed checkout  "
    document.dataViewId = dataViewId
    document.dateField = SavedDateField(field: "event.created", parts: ["event", "created"], type: "date")
    document.timeRange = range

    let saved = try manager.save(document)

    let stored = try #require(manager.document(id: saved.id))
    #expect(stored.title == "Failed checkout")
    #expect(stored.hostId == hostId)
    #expect(stored.docIndex == "logs-2026.10.10")
    #expect(stored.docId == "abc")
    #expect(stored.searchIndex == "logs-*")
    #expect(stored.dataViewId == dataViewId)
    #expect(stored.dateField == SavedDateField(field: "event.created", parts: ["event", "created"], type: "date"))
    #expect(stored.timeRange == range)
  }

  @Test func saveWithoutDateFieldOrPeriodReadsBackEmpty() throws {
    let saved = try manager.save(draft("abc"))
    let stored = try #require(manager.document(id: saved.id))
    #expect(stored.dateField == nil)
    #expect(stored.timeRange == nil)
    #expect(stored.dataViewId == nil)
  }

  @Test func saveRejectsAMissingReference() {
    #expect(throws: SavedDocumentError.missingReference) { try manager.save(draft("")) }
    #expect(throws: SavedDocumentError.missingReference) { try manager.save(draft("abc", index: "")) }
    #expect(realm.objects(RealmSavedDocument.self).isEmpty)
  }

  @Test func savingTheSameDocumentTwiceKeepsTheFirst() throws {
    var first = draft("abc")
    first.title = "First"
    let saved = try manager.save(first)

    var second = draft("abc")
    second.title = "Second"
    let again = try manager.save(second)

    #expect(again.id == saved.id)
    #expect(again.title == "First")
    #expect(realm.objects(RealmSavedDocument.self).count == 1)
  }

  @Test func theSameIdInAnotherIndexOrHostIsADifferentDocument() throws {
    try manager.save(draft("abc"))
    try manager.save(draft("abc", index: "logs-2026.10.11"))
    try manager.save(draft("abc", host: UUID()))
    #expect(realm.objects(RealmSavedDocument.self).count == 3)
  }

  // MARK: - Read

  @Test func documentsAreForOneHostNewestFirst() throws {
    try manager.save(draft("old", savedDate: Date(timeIntervalSince1970: 100)))
    try manager.save(draft("new", savedDate: Date(timeIntervalSince1970: 300)))
    try manager.save(draft("middle", savedDate: Date(timeIntervalSince1970: 200)))
    try manager.save(draft("elsewhere", host: UUID(), savedDate: Date(timeIntervalSince1970: 400)))

    #expect(manager.documents(hostId: hostId).map(\.docId) == ["new", "middle", "old"])
    #expect(manager.all().map(\.docId) == ["elsewhere", "new", "middle", "old"])
  }

  @Test func findMatchesHostIndexAndId() throws {
    let saved = try manager.save(draft("abc"))

    #expect(manager.find(hostId: hostId, ref: DocumentRef(index: "logs-2026.10.10", id: "abc"))?.id == saved.id)
    #expect(manager.find(hostId: hostId, ref: DocumentRef(index: "logs-2026.10.11", id: "abc")) == nil)
    #expect(manager.find(hostId: UUID(), ref: DocumentRef(index: "logs-2026.10.10", id: "abc")) == nil)
  }

  // MARK: - Rename

  @Test func renameTrimsAndAnEmptyTitleFallsBackToTheDefault() throws {
    let saved = try manager.save(draft("abc"))

    let renamed = try manager.rename(id: saved.id, title: "  Slow request ")
    #expect(renamed.displayTitle == "Slow request")

    let cleared = try manager.rename(id: saved.id, title: "   ")
    #expect(cleared.title == "")
    #expect(cleared.displayTitle == "logs-2026.10.10 / abc")
  }

  @Test func renamingAMissingDocumentThrows() {
    #expect(throws: SavedDocumentError.notFound) { try manager.rename(id: UUID(), title: "Gone") }
  }

  // MARK: - Delete

  @Test func deleteById() throws {
    let saved = try manager.save(draft("abc"))
    manager.delete(id: saved.id)
    #expect(manager.document(id: saved.id) == nil)
    // Deleting again is a no-op
    manager.delete(id: saved.id)
  }

  @Test func deleteByReferenceOnlyRemovesThatDocument() throws {
    try manager.save(draft("abc"))
    try manager.save(draft("def"))

    manager.delete(hostId: hostId, ref: DocumentRef(index: "logs-2026.10.10", id: "abc"))

    #expect(manager.documents(hostId: hostId).map(\.docId) == ["def"])
  }

  @Test func deleteByHostLeavesOtherHosts() throws {
    let otherHost = UUID()
    try manager.save(draft("abc"))
    try manager.save(draft("def"))
    try manager.save(draft("ghi", host: otherHost))

    manager.deleteByHost(id: hostId)

    #expect(manager.documents(hostId: hostId).isEmpty)
    #expect(manager.documents(hostId: otherHost).count == 1)
  }

  @Test func deleteIdsRemovesOnlyThoseDocuments() throws {
    let a = try manager.save(draft("a"))
    let b = try manager.save(draft("b"))
    try manager.save(draft("c"))

    manager.delete(ids: [a.id, b.id, UUID()])

    #expect(manager.all().map(\.docId) == ["c"])
    // No ids, or ids already gone, change nothing
    manager.delete(ids: [])
    manager.delete(ids: [a.id])
    #expect(manager.all().map(\.docId) == ["c"])
  }

  @Test func deleteAllRemovesEveryHostsDocuments() throws {
    try manager.save(draft("abc"))
    try manager.save(draft("def", host: UUID()))

    manager.deleteAll()

    #expect(manager.all().isEmpty)
    // Nothing left to remove is a no-op
    manager.deleteAll()
  }

  @Test func pruneOrphansRemovesDocumentsOfDeletedHosts() throws {
    let goneHost = UUID()
    try manager.save(draft("abc"))
    try manager.save(draft("def", host: goneHost))
    try manager.save(draft("ghi", host: goneHost))

    #expect(manager.pruneOrphans(validHostIds: [hostId]) == 2)
    #expect(manager.all().map(\.docId) == ["abc"])
    #expect(manager.pruneOrphans(validHostIds: [hostId]) == 0)
  }

  // MARK: - Relocate

  @Test func relocateMovesTheDocumentToItsNewIndex() throws {
    var document = draft("abc")
    document.title = "Failed checkout"
    let saved = try manager.save(document)

    let moved = try #require(manager.relocate(id: saved.id, to: "shrink-ab1c-logs-2026.10.10"))

    #expect(moved.id == saved.id)
    #expect(moved.docIndex == "shrink-ab1c-logs-2026.10.10")
    #expect(moved.title == "Failed checkout")
    #expect(manager.document(id: saved.id)?.docIndex == "shrink-ab1c-logs-2026.10.10")
    #expect(manager.find(hostId: hostId, ref: DocumentRef(index: "shrink-ab1c-logs-2026.10.10", id: "abc")) != nil)
    #expect(manager.find(hostId: hostId, ref: DocumentRef(index: "logs-2026.10.10", id: "abc")) == nil)
  }

  @Test func relocateToTheSameIndexChangesNothing() throws {
    let saved = try manager.save(draft("abc"))
    #expect(manager.relocate(id: saved.id, to: "logs-2026.10.10") == saved)
    #expect(manager.all() == [saved])
  }

  @Test func relocateOntoAnAlreadySavedCopyKeepsThatOne() throws {
    var old = draft("abc")
    old.title = "Failed checkout"
    let moved = try manager.save(old)
    let existing = try manager.save(draft("abc", index: "shrink-ab1c-logs-2026.10.10"))

    let kept = try #require(manager.relocate(id: moved.id, to: "shrink-ab1c-logs-2026.10.10"))

    #expect(kept.id == existing.id)
    // It had no title of its own, so it takes the moved one's
    #expect(kept.title == "Failed checkout")
    #expect(manager.all().map(\.id) == [existing.id])
  }

  @Test func relocateOntoACopyWithATitleKeepsItsTitle() throws {
    var old = draft("abc")
    old.title = "Old title"
    let moved = try manager.save(old)
    var copy = draft("abc", index: "restored-logs-2026.10.10")
    copy.title = "Kept title"
    let existing = try manager.save(copy)

    let kept = try #require(manager.relocate(id: moved.id, to: "restored-logs-2026.10.10"))

    #expect(kept.id == existing.id)
    #expect(kept.title == "Kept title")
    #expect(manager.document(id: moved.id) == nil)
  }

  @Test func relocateOnlyMergesWithTheSameHost() throws {
    let moved = try manager.save(draft("abc"))
    let otherHost = try manager.save(draft("abc", index: "shrink-logs-2026.10.10", host: UUID()))

    let relocated = try #require(manager.relocate(id: moved.id, to: "shrink-logs-2026.10.10"))

    #expect(relocated.id == moved.id)
    #expect(manager.all().count == 2)
    #expect(manager.document(id: otherHost.id)?.hostId == otherHost.hostId)
  }

  @Test func relocateAnUnknownDocumentOrToNoIndexIsNil() throws {
    #expect(manager.relocate(id: UUID(), to: "shrink-logs") == nil)
    let saved = try manager.save(draft("abc"))
    #expect(manager.relocate(id: saved.id, to: "") == nil)
    #expect(manager.document(id: saved.id)?.docIndex == "logs-2026.10.10")
  }

  // MARK: - Storage unavailable

  @Test func withoutADatabaseReadsAreEmptyAndSavesThrow() {
    let manager = SavedDocumentDataManager(realmProvider: { nil })
    #expect(manager.all().isEmpty)
    #expect(manager.find(hostId: hostId, ref: DocumentRef(index: "logs", id: "abc")) == nil)
    #expect(throws: SavedDocumentError.storageUnavailable) { try manager.save(draft("abc")) }
    #expect(manager.relocate(id: UUID(), to: "shrink-logs") == nil)
  }
}
