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
                             period: .absolute(from: range.start, to: range.end, fromNow: false, toNow: false),
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
    #expect(stored.period == .absolute(from: range.start, to: range.end, fromNow: false, toNow: false))
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
    #expect(stored.period == nil)
    #expect(stored.sortField == nil)
    #expect(stored.sortOrder == .Descending)
    #expect(stored.fieldFilters.isEmpty)
    #expect(stored.selectedFields.isEmpty)
  }

  @Test func aRelativePeriodIsStoredRelative() throws {
    var search = draft()
    search.dateField = SavedDateField(field: "@timestamp")
    search.period = .relative(value: 1, period: .Hours)

    let stored = try #require(manager.search(id: try manager.save(search).id))

    #expect(stored.period == .relative(value: 1, period: .Hours))
  }

  @Test func aPeriodStartingOrEndingNowIsStoredWithItsNowSide() throws {
    let from = Date(timeIntervalSince1970: 1_000)
    var search = draft()
    search.dateField = SavedDateField(field: "@timestamp")
    search.period = .absolute(from: from, to: Date(timeIntervalSince1970: 0), fromNow: false, toNow: true)

    let stored = try #require(manager.search(id: try manager.save(search).id))

    #expect(stored.period == .absolute(from: from, to: Date(timeIntervalSince1970: 0), fromNow: false, toNow: true))
  }

  @Test func updatingFromRelativeToFixedDatesClearsTheRelativePeriod() throws {
    var search = draft()
    search.dateField = SavedDateField(field: "@timestamp")
    search.period = .relative(value: 1, period: .Hours)
    let saved = try manager.save(search)

    let fixed = DateRangeSnapshot.absolute(from: Date(timeIntervalSince1970: 10), to: Date(timeIntervalSince1970: 20),
                                           fromNow: false, toNow: false)
    search.period = fixed
    try manager.update(id: saved.id, with: search)

    #expect(manager.search(id: saved.id)?.period == fixed)
  }

  @Test func aSearchSavedBeforeRelativePeriodsWereKeptReadsAsFixedDates() throws {
    // Older rows only have the two dates, with the newer columns at their defaults
    let object = RealmSavedSearch()
    object.id = UUID()
    object.hostId = hostId
    object.dateField = "@timestamp"
    object.rangeFrom = Date(timeIntervalSince1970: 10)
    object.rangeTo = Date(timeIntervalSince1970: 20)
    try realm.write { realm.add(object) }

    let stored = try #require(manager.search(id: object.id))

    #expect(stored.period == .absolute(from: Date(timeIntervalSince1970: 10), to: Date(timeIntervalSince1970: 20),
                                       fromNow: false, toNow: false))
    #expect(!stored.isPeriodLive)
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
    original.period = .relative(value: 15, period: .Minutes)
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
    #expect(stored.period == nil)
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

  @Test func deleteIdsRemovesOnlyThoseSearches() throws {
    let a = try manager.save(draft("a"))
    let b = try manager.save(draft("b"))
    try manager.save(draft("c"))

    manager.delete(ids: [a.id, b.id, UUID()])

    #expect(manager.all().map(\.query) == ["c"])
    // No ids, or ids already gone, change nothing
    manager.delete(ids: [])
    manager.delete(ids: [a.id])
    #expect(manager.all().map(\.query) == ["c"])
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
