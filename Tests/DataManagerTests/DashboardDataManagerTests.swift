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
struct DashboardDataManagerTests {

  // Each test gets its own in-memory database, nothing is shared
  let realm: Realm
  let manager: DashboardDataManager
  let searches: SavedSearchDataManager
  let hostId = UUID()

  init() throws {
    let realm = try Realm(configuration: Realm.Configuration(inMemoryIdentifier: UUID().uuidString,
                                                             schemaVersion: RealmManager.schemaVersion))
    self.realm = realm
    self.manager = DashboardDataManager(realmProvider: { realm })
    self.searches = SavedSearchDataManager(realmProvider: { realm })
  }

  private func savedSearch(host: UUID? = nil) throws -> SavedSearch {
    try searches.save(SavedSearch(hostId: host ?? hostId, searchIndex: "logs-*"))
  }

  /// A dashboard showing these saved searches, in order
  private func dashboard(showing searchIds: [UUID]) throws -> Dashboard {
    let created = try manager.create(title: "Ops")
    return try manager.addPanels(id: created.id, savedSearchIds: searchIds)
  }

  // MARK: - Dashboards

  @Test func createTrimsTheTitleAndStartsEmpty() throws {
    let created = try manager.create(title: "  Ops  ")
    let stored = try #require(manager.dashboard(id: created.id))
    #expect(stored.title == "Ops")
    #expect(stored.panels.isEmpty)
    #expect(stored.columns == Dashboard.defaultColumns)
    #expect(stored.refreshSeconds == 0)
    #expect(stored.updatedDate == nil)
  }

  @Test func anEmptyTitleTakesTheNextFreeName() throws {
    #expect(try manager.create().title == "Dashboard")
    #expect(try manager.create(title: " ").title == "Dashboard 2")
  }

  @Test func allIsOldestFirst() throws {
    let older = try manager.create(title: "Older", now: Date(timeIntervalSince1970: 1_000))
    let newer = try manager.create(title: "Newer", now: Date(timeIntervalSince1970: 2_000))
    #expect(manager.all().map(\.id) == [older.id, newer.id])
  }

  @Test func renameTrimsAndKeepsTheOldNameWhenEmpty() throws {
    let created = try manager.create(title: "Ops")
    #expect(try manager.rename(id: created.id, title: " Trading ").title == "Trading")
    #expect(try manager.rename(id: created.id, title: "  ").title == "Trading")
  }

  @Test func deleteRemovesOnlyThatDashboard() throws {
    let kept = try manager.create(title: "Kept")
    let removed = try manager.create(title: "Removed")
    manager.delete(id: removed.id)
    #expect(manager.all().map(\.id) == [kept.id])
  }

  @Test func columnsAreClampedAndMarkTheDashboardUpdated() throws {
    let created = try manager.create(title: "Ops")
    #expect(try manager.setColumns(id: created.id, columns: 3).columns == 3)
    #expect(try manager.setColumns(id: created.id, columns: 7).columns == 3)
    #expect(try manager.setColumns(id: created.id, columns: 0).columns == 1)
    #expect(manager.dashboard(id: created.id)?.updatedDate != nil)
  }

  @Test func refreshIntervalIsNeverNegative() throws {
    let created = try manager.create(title: "Ops")
    #expect(try manager.setRefreshInterval(id: created.id, seconds: 60).refreshSeconds == 60)
    #expect(try manager.setRefreshInterval(id: created.id, seconds: -5).refreshSeconds == 0)
  }

  @Test func changingAMissingDashboardThrows() {
    #expect(throws: SavedDocumentError.notFound) {
      try manager.addPanels(id: UUID(), savedSearchIds: [UUID()])
    }
  }

  // MARK: - Panels

  @Test func addingPanelsAppendsThemAndSkipsSearchesAlreadyShown() throws {
    let first = try savedSearch()
    let second = try savedSearch()
    let created = try dashboard(showing: [first.id])

    let updated = try manager.addPanels(id: created.id, savedSearchIds: [second.id, first.id, second.id])

    #expect(updated.panels.map(\.savedSearchId) == [first.id, second.id])
    #expect(updated.panels.allSatisfy { $0.width == .single && $0.height == .medium })
  }

  @Test func removePanelRemovesOnlyThatPanel() throws {
    let first = try savedSearch()
    let second = try savedSearch()
    let created = try dashboard(showing: [first.id, second.id])

    let updated = try manager.removePanel(id: created.id, panelId: created.panels[0].id)

    #expect(updated.panels.map(\.savedSearchId) == [second.id])
  }

  @Test func setPanelOrderKeepsPanelsLeftOutAfterTheOnesGiven() throws {
    let ids = try (0..<4).map { _ in try savedSearch().id }
    let created = try dashboard(showing: ids)
    let panels = created.panels.map(\.id)

    let updated = try manager.setPanelOrder(id: created.id, panelIds: [panels[2], panels[0]])

    #expect(updated.panels.map(\.id) == [panels[2], panels[0], panels[1], panels[3]])
    // Panels keep their own ids and sizes when they move
    #expect(updated.panels.map(\.savedSearchId) == [ids[2], ids[0], ids[1], ids[3]])
  }

  @Test func setPanelSizeChangesOnlyThatPanel() throws {
    let created = try dashboard(showing: [try savedSearch().id, try savedSearch().id])

    let updated = try manager.setPanelSize(id: created.id, panelId: created.panels[1].id, width: .full, height: .large)

    #expect(updated.panels.map(\.width) == [.single, .full])
    #expect(updated.panels.map(\.height) == [.medium, .large])
    #expect(manager.dashboard(id: created.id)?.panels.map(\.height) == [.medium, .large])
  }

  // MARK: - Saved searches going away

  @Test func deletingASavedSearchTakesItOffEveryDashboard() throws {
    let removed = try savedSearch()
    let kept = try savedSearch()
    let one = try dashboard(showing: [removed.id, kept.id])
    let two = try dashboard(showing: [removed.id])

    searches.delete(id: removed.id)

    #expect(manager.dashboard(id: one.id)?.panels.map(\.savedSearchId) == [kept.id])
    #expect(manager.dashboard(id: two.id)?.panels.isEmpty == true)
  }

  @Test func deletingSeveralSavedSearchesTakesThemAllOff() throws {
    let ids = try (0..<3).map { _ in try savedSearch().id }
    let created = try dashboard(showing: ids)

    searches.delete(ids: [ids[0], ids[2]])

    #expect(manager.dashboard(id: created.id)?.panels.map(\.savedSearchId) == [ids[1]])
  }

  @Test func deletingEverySavedSearchEmptiesEveryDashboardButKeepsThem() throws {
    let created = try dashboard(showing: [try savedSearch().id, try savedSearch().id])

    searches.deleteAll()

    #expect(manager.dashboard(id: created.id)?.panels.isEmpty == true)
  }

  @Test func deletingAHostsSearchesTakesThemOff() throws {
    let otherHost = UUID()
    let gone = try savedSearch(host: otherHost)
    let kept = try savedSearch()
    let created = try dashboard(showing: [gone.id, kept.id])

    searches.deleteByHost(id: otherHost)

    #expect(manager.dashboard(id: created.id)?.panels.map(\.savedSearchId) == [kept.id])
  }

  @Test func pruningOrphanedSearchesTakesThemOff() throws {
    let orphan = try savedSearch(host: UUID())
    let kept = try savedSearch()
    let created = try dashboard(showing: [orphan.id, kept.id])

    searches.pruneOrphans(validHostIds: [hostId])

    #expect(manager.dashboard(id: created.id)?.panels.map(\.savedSearchId) == [kept.id])
  }

  @Test func pruneMissingSearchesRemovesPanelsForSearchesThatAreGone() throws {
    let kept = try savedSearch()
    let missing = UUID()
    let one = try dashboard(showing: [missing, kept.id])
    let two = try dashboard(showing: [missing])

    let removed = manager.pruneMissingSearches(validSearchIds: [kept.id])

    #expect(removed == 2)
    #expect(manager.dashboard(id: one.id)?.panels.map(\.savedSearchId) == [kept.id])
    #expect(manager.dashboard(id: two.id)?.panels.isEmpty == true)
  }

  @Test func withoutADatabaseReadsAreEmptyAndChangesThrow() {
    let manager = DashboardDataManager(realmProvider: { nil })
    #expect(manager.all().isEmpty)
    #expect(manager.dashboard(id: UUID()) == nil)
    #expect(manager.pruneMissingSearches(validSearchIds: []) == 0)
    #expect(throws: SavedDocumentError.storageUnavailable) {
      try manager.create(title: "Ops")
    }
  }
}
