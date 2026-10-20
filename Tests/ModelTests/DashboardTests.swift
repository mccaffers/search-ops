// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import Testing
import OrderedCollections

@testable import Search_Ops

struct DashboardTests {

  // MARK: - Dashboard

  @Test func columnsAreKeptBetweenOneAndThree() {
    #expect(Dashboard(title: "A", columns: 0).columns == 1)
    #expect(Dashboard(title: "A", columns: 2).columns == 2)
    #expect(Dashboard(title: "A", columns: 9).columns == 3)
    #expect(Dashboard(title: "A").columns == Dashboard.defaultColumns)
  }

  @Test func newTitlesSkipTakenNamesWhateverTheirCase() {
    #expect(Dashboard.newTitle(existing: []) == "Dashboard")
    #expect(Dashboard.newTitle(existing: ["Errors"]) == "Dashboard")
    #expect(Dashboard.newTitle(existing: ["dashboard "]) == "Dashboard 2")
    #expect(Dashboard.newTitle(existing: ["Dashboard", "Dashboard 2", "Dashboard 4"]) == "Dashboard 3")
  }

  @Test func draggingAPanelOntoAnotherTakesItsPlace() {
    let ids = (0..<4).map { _ in UUID() }
    // Forwards: the panels in between move back by one
    #expect(Dashboard.reordered(ids, moving: ids[0], onto: ids[2]) == [ids[1], ids[2], ids[0], ids[3]])
    // Backwards: the panels in between move along by one
    #expect(Dashboard.reordered(ids, moving: ids[3], onto: ids[1]) == [ids[0], ids[3], ids[1], ids[2]])
    // Onto itself, or an id that isn't there, changes nothing
    #expect(Dashboard.reordered(ids, moving: ids[1], onto: ids[1]) == ids)
    #expect(Dashboard.reordered(ids, moving: UUID(), onto: ids[1]) == ids)
  }

  @Test func savedSearchIdsAreListedOnceInGridOrder() {
    let first = UUID()
    let second = UUID()
    let dashboard = Dashboard(title: "A", panels: [DashboardPanel(savedSearchId: second),
                                                   DashboardPanel(savedSearchId: first),
                                                   DashboardPanel(savedSearchId: second)])
    #expect(dashboard.savedSearchIds == [second, first])
  }

  @Test func panelsFillRowsOfTheNumberOfColumns() {
    let panels = (0..<5).map { _ in DashboardPanel(savedSearchId: UUID()) }
    let rows = Dashboard.rows(panels, columns: 2)
    #expect(rows.map { $0.map(\.id) } == [[panels[0].id, panels[1].id],
                                          [panels[2].id, panels[3].id],
                                          [panels[4].id]])
    #expect(Dashboard.rows(panels, columns: 1).count == 5)
    #expect(Dashboard.rows([], columns: 3).isEmpty)
  }

  @Test func aFullWidthPanelTakesARowOfItsOwn() {
    let a = DashboardPanel(savedSearchId: UUID())
    let wide = DashboardPanel(savedSearchId: UUID(), width: .full)
    let b = DashboardPanel(savedSearchId: UUID())
    let c = DashboardPanel(savedSearchId: UUID())
    // It ends the row it interrupts early, and the panels after it start a new row
    let rows = Dashboard.rows([a, wide, b, c], columns: 3)
    #expect(rows.map { $0.map(\.id) } == [[a.id], [wide.id], [b.id, c.id]])
  }

  @Test func refreshTitles() {
    #expect(Dashboard.refreshTitle(0) == "Off")
    #expect(Dashboard.refreshTitle(30) == "30 seconds")
    #expect(Dashboard.refreshTitle(60) == "1 minute")
    #expect(Dashboard.refreshTitle(900) == "15 minutes")
  }

  @Test func biggerPanelsSearchForMoreDocuments() {
    #expect(DashboardPanelHeight.small.rowLimit < DashboardPanelHeight.medium.rowLimit)
    #expect(DashboardPanelHeight.medium.rowLimit < DashboardPanelHeight.large.rowLimit)
  }

  // MARK: - Panel columns and cells

  @Test func columnsStartWithTheDateThenTheSavedFieldsInOrder() {
    let columns = DashboardPanelSearch.columns(dateField: "@timestamp", selectedFields: ["status", "@timestamp", "host"])
    #expect(columns == [.date("@timestamp"), .field("status"), .field("host")])
  }

  @Test func aSearchSavedWithoutColumnsShowsTheWholeDocument() {
    #expect(DashboardPanelSearch.columns(dateField: "@timestamp", selectedFields: []) == [.date("@timestamp"), .document])
    #expect(DashboardPanelSearch.columns(dateField: nil, selectedFields: []) == [.document])
    #expect(DashboardPanelSearch.columns(dateField: "", selectedFields: ["a"]) == [.field("a")])
  }

  @Test func cellsJoinValuesAndLeaveMissingFieldsEmpty() {
    let document: OrderedDictionary<String, Any> = ["@timestamp": ["2026-10-20T09:15:00Z"],
                                                    "tags": ["a", " ", "b"],
                                                    "blank": [" "]]
    let columns: [DashboardColumn] = [.field("tags"), .field("blank"), .field("missing")]
    let rows = DashboardPanelSearch.rows([document], columns: columns, dateField: "@timestamp")
    #expect(rows == [DashboardRow(id: 0, cells: ["a, b", nil, nil])])
  }

  @Test func theDateCellIsFormatted() throws {
    let raw = "2026-10-20T09:15:00Z"
    let document: OrderedDictionary<String, Any> = ["@timestamp": [raw]]
    let text = try #require(DashboardPanelSearch.text(for: .date("@timestamp"), in: document, dateField: "@timestamp"))
    #expect(text == DateTools.buildDateLarge(input: raw))
    #expect(text != raw)
  }

  @Test func theDocumentCellSummarisesEveryFieldButTheDate() {
    let document: OrderedDictionary<String, Any> = ["@timestamp": ["2026-10-20T09:15:00Z"],
                                                    "status": ["500"],
                                                    "empty": [""],
                                                    "tags": ["a", "b"]]
    let text = DashboardPanelSearch.text(for: .document, in: document, dateField: "@timestamp")
    #expect(text == "status: 500  tags: a, b")
  }

  @Test func longDocumentSummariesAreCutOff() throws {
    var document = OrderedDictionary<String, Any>()
    for index in 0..<100 {
      document["field\(index)"] = [String(repeating: "x", count: 20)]
    }
    let text = try #require(DashboardPanelSearch.text(for: .document, in: document, dateField: nil))
    #expect(text.count == DashboardPanelSearch.summaryLength + 1)
    #expect(text.hasSuffix("…"))
  }

  @Test func aDocumentWithNothingButTheDateHasNoSummary() {
    let document: OrderedDictionary<String, Any> = ["@timestamp": ["2026-10-20T09:15:00Z"]]
    #expect(DashboardPanelSearch.text(for: .document, in: document, dateField: "@timestamp") == nil)
  }
}
