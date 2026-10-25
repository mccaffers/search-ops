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

  @Test func newTitlesSkipTakenNamesWhateverTheirCase() {
    #expect(Dashboard.newTitle(existing: []) == "Dashboard")
    #expect(Dashboard.newTitle(existing: ["Errors"]) == "Dashboard")
    #expect(Dashboard.newTitle(existing: ["dashboard "]) == "Dashboard 2")
    #expect(Dashboard.newTitle(existing: ["Dashboard", "Dashboard 2", "Dashboard 4"]) == "Dashboard 3")
  }

  @Test func panelsAreInReadingOrder() {
    let bottom = DashboardPanel(savedSearchId: UUID(), frame: DashboardGridFrame(x: 0, y: 7, w: 6, h: 3))
    let right = DashboardPanel(savedSearchId: UUID(), frame: DashboardGridFrame(x: 6, y: 0, w: 6, h: 7))
    let left = DashboardPanel(savedSearchId: UUID(), frame: DashboardGridFrame(x: 0, y: 0, w: 6, h: 7))
    let dashboard = Dashboard(title: "A", panels: [bottom, right, left])
    #expect(dashboard.panels.map(\.id) == [left.id, right.id, bottom.id])
  }

  @Test func movingPanelsKeepsReadingOrderAndLeavesOthersWhereTheyAre() {
    let a = DashboardPanel(savedSearchId: UUID(), frame: DashboardGridFrame(x: 0, y: 0, w: 6, h: 7))
    let b = DashboardPanel(savedSearchId: UUID(), frame: DashboardGridFrame(x: 6, y: 0, w: 6, h: 7))
    let moved = Dashboard(title: "A", panels: [a, b]).with(frames: [a.id: DashboardGridFrame(x: 0, y: 7, w: 12, h: 3)])
    #expect(moved.panels.map(\.id) == [b.id, a.id])
    #expect(moved.frames == [a.id: DashboardGridFrame(x: 0, y: 7, w: 12, h: 3), b.id: b.frame])
  }

  @Test func savedSearchIdsAreListedOnceInReadingOrder() {
    let first = UUID()
    let second = UUID()
    func at(_ x: Int, _ y: Int) -> DashboardGridFrame { DashboardGridFrame(x: x, y: y, w: 6, h: 3) }
    let dashboard = Dashboard(title: "A", panels: [DashboardPanel(savedSearchId: second, frame: at(0, 3)),
                                                   DashboardPanel(savedSearchId: first, frame: at(6, 0)),
                                                   DashboardPanel(savedSearchId: second, frame: at(0, 0))])
    #expect(dashboard.savedSearchIds == [second, first])
  }

  @Test func refreshTitles() {
    #expect(Dashboard.refreshTitle(0) == "Off")
    #expect(Dashboard.refreshTitle(30) == "30 seconds")
    #expect(Dashboard.refreshTitle(60) == "1 minute")
    #expect(Dashboard.refreshTitle(900) == "15 minutes")
    #expect(Dashboard.shortRefreshTitle(0) == "Off")
    #expect(Dashboard.shortRefreshTitle(30) == "30s")
    #expect(Dashboard.shortRefreshTitle(60) == "1m")
    #expect(Dashboard.shortRefreshTitle(900) == "15m")
  }

  @Test func tallerPanelsSearchForMoreDocuments() {
    let short = DashboardPanel(savedSearchId: UUID(), frame: DashboardGridFrame(x: 0, y: 0, w: 6, h: 5))
    let tall = DashboardPanel(savedSearchId: UUID(), frame: DashboardGridFrame(x: 0, y: 0, w: 6, h: 12))
    #expect(short.rowLimit < tall.rowLimit)
    #expect(tall.rowLimit == DashboardLayout.rowLimit(height: 12))
  }

  // MARK: - Column widths

  /// Every character 6 points wide, headers 7
  private func measure(_ text: String, _ bold: Bool) -> Double {
    Double(text.count) * (bold ? 7 : 6)
  }

  @Test func columnsAreKeyedLikeTheSearchTab() {
    #expect(DashboardColumn.date("@timestamp").savedKey == "date:@timestamp")
    #expect(DashboardColumn.field("status").savedKey == "field:status")
    #expect(DashboardColumn.document.savedKey == "document")
  }

  @Test func automaticWidthsFitTheWidestHeaderOrCellWithinTheLimits() {
    let columns: [DashboardColumn] = [.field("env"), .field("message"), .field("id")]
    let rows = [DashboardRow(id: 0, cells: ["demo", String(repeating: "x", count: 500), nil]),
                DashboardRow(id: 1, cells: ["production", "short", nil])]
    let widths = DashboardColumnWidths.automatic(columns: columns, rows: rows, measure: measure)
    // "production" is 60 wide, plus padding
    #expect(widths[.field("env")] == 60 + DashboardColumnWidths.cellPadding)
    #expect(widths[.field("message")] == DashboardColumnWidths.maxWidth)
    #expect(widths[.field("id")] == DashboardColumnWidths.minWidth)
  }

  @Test func aPanelsWidthWinsOverTheSearchsWhichWinsOverTheAutomaticOne() {
    let columns: [DashboardColumn] = [.field("a"), .field("b"), .field("c")]
    let automatic: [DashboardColumn: Double] = [.field("a"): 80, .field("b"): 80, .field("c"): 80]
    let result = DashboardColumnWidths.preferred(columns: columns,
                                                 automatic: automatic,
                                                 search: ["field:a": 200, "field:b": 150],
                                                 panel: ["field:a": 120, "field:c": 9000])
    #expect(result.widths == [.field("a"): 120, .field("b"): 150, .field("c"): DashboardColumnWidths.maxSetWidth])
    #expect(result.set == [.field("a"), .field("b"), .field("c")])
    // Nothing set: all automatic
    #expect(DashboardColumnWidths.preferred(columns: columns, automatic: automatic, search: [:], panel: [:]).set.isEmpty)
  }

  @Test func theLastColumnFillsTheRestOfTheRow() {
    let columns: [DashboardColumn] = [.date("@timestamp"), .field("env"), .field("message")]
    let preferred: [DashboardColumn: Double] = [.date("@timestamp"): 160, .field("env"): 80, .field("message"): 300]
    let widths = DashboardColumnWidths.fitted(columns: columns, preferred: preferred, set: [], available: 900)
    #expect(widths == [160, 80, 660])
  }

  @Test func whenRoomRunsOutFittedColumnsShrinkBeforeSetOnes() {
    let columns: [DashboardColumn] = [.field("a"), .field("b"), .field("c")]
    let preferred: [DashboardColumn: Double] = [.field("a"): 260, .field("b"): 160, .field("c"): 100]
    // a and b want 420, leaving 30 for c: 30 short of its 60
    let widths = DashboardColumnWidths.fitted(columns: columns, preferred: preferred, set: [.field("b")], available: 450)
    #expect(widths == [230, 160, 60])
    // Fitted columns can't go below 60, so then the set one gives way too
    let tight = DashboardColumnWidths.fitted(columns: columns, preferred: preferred, set: [.field("b")], available: 200)
    #expect(tight[0] == DashboardColumnWidths.minWidth)
    #expect(tight[1] == 80)
    #expect(tight[2] == DashboardColumnWidths.minWidth)
    #expect(tight.reduce(0, +) == 200)
  }

  @Test func fittingToContentsGoesPastTheAutomaticLimitKeyedForSaving() {
    let columns: [DashboardColumn] = [.field("message"), .field("id")]
    let rows = [DashboardRow(id: 0, cells: [String(repeating: "x", count: 100), nil])]
    let widths = DashboardColumnWidths.fittedToContents(columns: columns, rows: rows, measure: measure)
    #expect(widths["field:message"] == 600 + DashboardColumnWidths.cellPadding)
    // Only the header: "id" in bold
    #expect(widths["field:id"] == 14 + DashboardColumnWidths.cellPadding)
  }

  @Test func aSingleColumnTakesTheWholeRow() {
    #expect(DashboardColumnWidths.fitted(columns: [.document], preferred: [.document: 300], set: [], available: 500) == [500])
    #expect(DashboardColumnWidths.fitted(columns: [], preferred: [:], set: [], available: 500).isEmpty)
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
