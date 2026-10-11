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
struct SavedSearchDataManagerTests {

  // Each test gets its own in-memory database, nothing is shared
  let realm: Realm
  let manager: SavedSearchDataManager
  let hostId = UUID()

  init() throws {
    let realm = try Realm(configuration: Realm.Configuration(inMemoryIdentifier: UUID().uuidString,
                                                             schemaVersion: RealmManager.schemaVersion))
    self.realm = realm
    self.manager = SavedSearchDataManager(realmProvider: { realm })
  }

  private func draft(_ query: String = "", host: UUID? = nil, savedDate: Date = Date.now) -> SavedSearch {
    SavedSearch(hostId: host ?? hostId, searchIndex: "logs-*", query: query, savedDate: savedDate)
  }

  @Test func saveStoresEverything() throws {
    let range = DateInterval(start: Date(timeIntervalSince1970: 1_000), end: Date(timeIntervalSince1970: 5_000))
    let dataViewId = UUID()
    let search = SavedSearch(hostId: hostId,
                             title: "  Errors  ",
                             searchIndex: "live-trading-*",
                             dataViewId: dataViewId,
                             dateField: SavedDateField(field: "event.created", parts: ["event", "created"], type: "date"),
                             timeRange: range,
                             query: "status:500",
                             fieldFilters: [FieldFilter(field: "host.name", value: "a"),
                                            FieldFilter(field: "cpu1", value: "0", negated: true, disabled: true)],
                             selectedFields: ["zeta", "alpha"],
                             columnWidths: ["date:date": 512.5, "field:dayClose": 82],
                             sortField: SavedDateField(field: "cpu0", type: "float"),
                             sortOrder: .Ascending)

    let saved = try manager.save(search)

    let stored = try #require(manager.search(id: saved.id))
    #expect(stored.title == "Errors")
    #expect(stored.hostId == hostId)
    #expect(stored.searchIndex == "live-trading-*")
    #expect(stored.dataViewId == dataViewId)
    #expect(stored.dateField == SavedDateField(field: "event.created", parts: ["event", "created"], type: "date"))
    #expect(stored.timeRange == range)
    #expect(stored.query == "status:500")
    #expect(stored.fieldFilters.map(\.field) == ["host.name", "cpu1"])
    #expect(stored.fieldFilters.map(\.negated) == [false, true])
    #expect(stored.fieldFilters.map(\.disabled) == [false, true])
    // Column order is kept, not sorted
    #expect(stored.selectedFields == ["zeta", "alpha"])
    #expect(stored.columnWidths == ["date:date": 512.5, "field:dayClose": 82])
    #expect(stored.sortField == SavedDateField(field: "cpu0", type: "float"))
    #expect(stored.sortOrder == .Ascending)
  }

  @Test func aSearchWithNothingOptionalReadsBackEmpty() throws {
    let saved = try manager.save(draft())
    let stored = try #require(manager.search(id: saved.id))
    #expect(stored.dateField == nil)
    #expect(stored.timeRange == nil)
    #expect(stored.sortField == nil)
    #expect(stored.sortOrder == .Descending)
    #expect(stored.fieldFilters.isEmpty)
    #expect(stored.selectedFields.isEmpty)
  }

  @Test func theSameSearchCanBeSavedTwice() throws {
    try manager.save(draft("status:500"))
    try manager.save(draft("status:500"))
    #expect(manager.all().count == 2)
  }

  @Test func allIsNewestFirst() throws {
    try manager.save(draft("old", savedDate: Date(timeIntervalSince1970: 100)))
    try manager.save(draft("new", savedDate: Date(timeIntervalSince1970: 300)))
    try manager.save(draft("middle", savedDate: Date(timeIntervalSince1970: 200)))
    #expect(manager.all().map(\.query) == ["new", "middle", "old"])
  }

  @Test func updateReplacesTheSearchButKeepsItsNameAndSavedDate() throws {
    var original = draft("status:500", savedDate: Date(timeIntervalSince1970: 100))
    original.title = "Errors"
    original.fieldFilters = [FieldFilter(field: "a", value: "1")]
    original.selectedFields = ["cpu0"]
    original.columnWidths = ["field:cpu0": 120, "document": 400]
    original.dateField = SavedDateField(field: "@timestamp")
    original.timeRange = DateInterval(start: Date(timeIntervalSince1970: 10), end: Date(timeIntervalSince1970: 20))
    original.sortField = SavedDateField(field: "cpu0")
    let saved = try manager.save(original)
    #expect(saved.updatedDate == nil)

    let changed = SavedSearch(hostId: hostId,
                              title: "Ignored",
                              searchIndex: "backtest-*",
                              query: "status:404",
                              fieldFilters: [FieldFilter(field: "b", value: "2", negated: true)],
                              selectedFields: ["cpu2", "cpu1"],
                              columnWidths: ["field:cpu2": 90],
                              sortOrder: .Ascending)
    let updatedAt = Date(timeIntervalSince1970: 500)
    let updated = try manager.update(id: saved.id, with: changed, now: updatedAt)

    let stored = try #require(manager.search(id: saved.id))
    // Filter chips get new ids each time they're read, so compare what matters
    #expect(updated.id == saved.id)
    #expect(updated.updatedDate == updatedAt)
    #expect(stored.id == saved.id)
    #expect(stored.title == "Errors")
    #expect(stored.savedDate == Date(timeIntervalSince1970: 100))
    #expect(stored.updatedDate == updatedAt)
    #expect(stored.searchIndex == "backtest-*")
    #expect(stored.query == "status:404")
    #expect(stored.fieldFilters.map(\.field) == ["b"])
    #expect(stored.fieldFilters.first?.negated == true)
    #expect(stored.selectedFields == ["cpu2", "cpu1"])
    #expect(stored.columnWidths == ["field:cpu2": 90])
    // Cleared when the search no longer has them
    #expect(stored.dateField == nil)
    #expect(stored.timeRange == nil)
    #expect(stored.sortField == nil)
    #expect(stored.sortOrder == .Ascending)
    #expect(manager.all().count == 1)
  }

  @Test func updatingAMissingSearchThrows() {
    #expect(throws: SavedDocumentError.notFound) { try manager.update(id: UUID(), with: draft()) }
  }

  @Test func renameTrimsAndAnEmptyTitleFallsBackToTheSummary() throws {
    let saved = try manager.save(draft("status:500"))
    #expect(try manager.rename(id: saved.id, title: " Errors ").displayTitle == "Errors")
    #expect(try manager.rename(id: saved.id, title: "").displayTitle == "status:500")
    #expect(throws: SavedDocumentError.notFound) { try manager.rename(id: UUID(), title: "Gone") }
  }

  @Test func deleteRemovesOnlyThatSearch() throws {
    let first = try manager.save(draft("a"))
    try manager.save(draft("b"))
    manager.delete(id: first.id)
    #expect(manager.all().map(\.query) == ["b"])
  }

  @Test func deleteAllRemovesEveryHostsSearches() throws {
    try manager.save(draft("a"))
    try manager.save(draft("b", host: UUID()))

    manager.deleteAll()

    #expect(manager.all().isEmpty)
    manager.deleteAll()
  }

  @Test func deleteByHostAndPruneOrphans() throws {
    let otherHost = UUID()
    let goneHost = UUID()
    try manager.save(draft("mine"))
    try manager.save(draft("other", host: otherHost))
    try manager.save(draft("gone", host: goneHost))

    manager.deleteByHost(id: hostId)
    #expect(Set(manager.all().map(\.query)) == ["other", "gone"])

    #expect(manager.pruneOrphans(validHostIds: [otherHost]) == 1)
    #expect(manager.all().map(\.query) == ["other"])
  }

  @Test func withoutADatabaseReadsAreEmptyAndSavesThrow() {
    let manager = SavedSearchDataManager(realmProvider: { nil })
    #expect(manager.all().isEmpty)
    #expect(throws: SavedDocumentError.storageUnavailable) { try manager.save(draft()) }
  }
}
