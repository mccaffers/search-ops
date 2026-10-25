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

  @Test func layoutChangesMarkTheDashboardUpdated() throws {
    let created = try dashboard(showing: [try savedSearch().id])
    try manager.setPanelSize(id: created.id, panelId: created.panels[0].id, w: 12, h: 5)
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

  @Test func addingPanelsFillsTheGridAndSkipsSearchesAlreadyShown() throws {
    let first = try savedSearch()
    let second = try savedSearch()
    let third = try savedSearch()
    let created = try dashboard(showing: [first.id])

    let updated = try manager.addPanels(id: created.id, savedSearchIds: [second.id, first.id, second.id, third.id])

    #expect(updated.panels.map(\.savedSearchId) == [first.id, second.id, third.id])
    let w = DashboardLayout.defaultWidth, h = DashboardLayout.defaultHeight
    #expect(updated.panels.map(\.frame) == [DashboardGridFrame(x: 0, y: 0, w: w, h: h),
                                            DashboardGridFrame(x: w, y: 0, w: w, h: h),
                                            DashboardGridFrame(x: 0, y: h, w: w, h: h)])
  }

  @Test func aNewPanelFillsTheGapLeftByARemovedOne() throws {
    let ids = try (0..<3).map { _ in try savedSearch().id }
    let created = try dashboard(showing: Array(ids[0..<2]))
    let removed = try manager.removePanel(id: created.id, panelId: created.panels[0].id)

    let updated = try manager.addPanels(id: removed.id, savedSearchIds: [ids[2]])

    #expect(updated.panels.first { $0.savedSearchId == ids[2] }?.frame.x == 0)
    #expect(updated.panels.first { $0.savedSearchId == ids[2] }?.frame.y == 0)
  }

  @Test func removePanelRemovesOnlyThatPanelAndThePanelsBelowRise() throws {
    let ids = try (0..<3).map { _ in try savedSearch().id }
    let created = try dashboard(showing: ids)

    let updated = try manager.removePanel(id: created.id, panelId: created.panels[0].id)

    #expect(updated.panels.map(\.savedSearchId) == [ids[2], ids[1]])
    #expect(updated.panels.map(\.frame.y) == [0, 0])
    #expect(manager.dashboard(id: created.id) == updated)
  }

  @Test func setLayoutSavesTheFramesAndTidiesOverlaps() throws {
    let ids = try (0..<2).map { _ in try savedSearch().id }
    let created = try dashboard(showing: ids)
    let a = created.panels[0].id, b = created.panels[1].id

    // B dropped on top of A, and a panel that isn't on the dashboard
    let updated = try manager.setLayout(id: created.id, frames: [b: DashboardGridFrame(x: 0, y: 0, w: 12, h: 4),
                                                                 UUID(): DashboardGridFrame(x: 0, y: 0, w: 2, h: 3)])

    #expect(updated.panels.count == 2)
    #expect(updated.frames[b] == DashboardGridFrame(x: 0, y: 0, w: 12, h: 4))
    #expect(updated.frames[a]?.y == 4)
    #expect(manager.dashboard(id: created.id) == updated)
  }

  @Test func setPanelSizePushesThePanelsInItsWayBelow() throws {
    let created = try dashboard(showing: [try savedSearch().id, try savedSearch().id])
    let a = created.panels[0].id, b = created.panels[1].id

    let updated = try manager.setPanelSize(id: created.id, panelId: a, w: 12, h: 4)

    #expect(updated.frames[a] == DashboardGridFrame(x: 0, y: 0, w: 12, h: 4))
    #expect(updated.frames[b]?.y == 4)
    #expect(manager.dashboard(id: created.id)?.frames == updated.frames)
  }

  @Test func columnWidthsAreSavedOnThePanelAndLeaveTheSearchAlone() throws {
    let search = try savedSearch()
    let created = try dashboard(showing: [search.id, try savedSearch().id])
    let panel = created.panels[0].id

    let updated = try manager.setColumnWidths(id: created.id, panelId: panel,
                                              widths: ["field:env": 90, "field:message": 99_999, "field:gone": 0])

    #expect(updated.panels[0].columnWidths == ["field:env": 90, "field:message": DashboardColumnWidths.maxSetWidth])
    #expect(updated.panels[1].columnWidths.isEmpty)
    #expect(manager.dashboard(id: created.id)?.panels[0].columnWidths == updated.panels[0].columnWidths)
    #expect(searches.all().first { $0.id == search.id }?.columnWidths.isEmpty == true)
  }

  @Test func columnWidthsSurviveMovingAndResizingAndCanBeReset() throws {
    let created = try dashboard(showing: [try savedSearch().id, try savedSearch().id])
    let panel = created.panels[0].id
    try manager.setColumnWidths(id: created.id, panelId: panel, widths: ["field:env": 90])

    try manager.setPanelSize(id: created.id, panelId: panel, w: 12, h: 5)
    let moved = try manager.setLayout(id: created.id, frames: [panel: DashboardGridFrame(x: 0, y: 9, w: 12, h: 5)])
    #expect(moved.panels.first { $0.id == panel }?.columnWidths == ["field:env": 90])

    let reset = try manager.setColumnWidths(id: created.id, panelId: panel, widths: [:])
    #expect(reset.panels.first { $0.id == panel }?.columnWidths.isEmpty == true)
  }

  @Test func panelsSavedBeforeTheGridKeepTheirLayout() throws {
    let ids = (0..<3).map { _ in UUID() }
    let panelIds = (0..<3).map { _ in UUID() }
    let object = RealmDashboard()
    object.id = UUID()
    object.title = "Old"
    object.columns = 2
    for (index, size) in [("single", "small"), ("single", "large"), ("full", "")].enumerated() {
      let panel = RealmDashboardPanel()
      panel.id = panelIds[index]
      panel.savedSearchId = ids[index]
      panel.width = size.0
      panel.height = size.1
      object.panels.append(panel)
    }
    try realm.write { realm.add(object) }

    let frames = try #require(manager.dashboard(id: object.id)).frames

    #expect(frames[panelIds[0]] == DashboardGridFrame(x: 0, y: 0, w: 6, h: DashboardLayout.height(fitting: 5)))
    #expect(frames[panelIds[1]] == DashboardGridFrame(x: 6, y: 0, w: 6, h: DashboardLayout.height(fitting: 20)))
    // Medium when there's no height, and on a row of its own below the taller of the two
    #expect(frames[panelIds[2]] == DashboardGridFrame(x: 0, y: DashboardLayout.height(fitting: 20), w: 12,
                                                      h: DashboardLayout.height(fitting: 10)))
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
