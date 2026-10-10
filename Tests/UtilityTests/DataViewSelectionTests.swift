// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import Testing

@testable import Search_Ops

struct DataViewSelectionTests {

  let hostId = UUID()

  private func view(_ name: String, _ pattern: String) -> DataView {
    DataView(hostId: hostId, name: name, pattern: pattern)
  }

  // MARK: - Matching indices

  @Test func matchingIndicesKeepsListOrder() {
    let indexes = ["live-logs", "live-trading-2026.07.12", "backtesting-report", "live-trading-2026.07.11"]
    #expect(DataViewSelection.matchingIndices(for: "live-trading-*", in: indexes)
            == ["live-trading-2026.07.12", "live-trading-2026.07.11"])
    #expect(DataViewSelection.matchingIndices(for: "live-logs,backtesting-*", in: indexes)
            == ["live-logs", "backtesting-report"])
    #expect(DataViewSelection.matchingIndices(for: "nothing-*", in: indexes).isEmpty)
  }

  // MARK: - Keep

  @Test func keepsTheViewWhileTheIndexIsItsPattern() {
    let live = view("Live trading", "live-trading-*")
    #expect(DataViewSelection.keep(live, forIndex: "live-trading-*") == live)
    #expect(DataViewSelection.keep(live, forIndex: "live-trading-2026.07.11") == nil)
    #expect(DataViewSelection.keep(live, forIndex: "") == nil)
    #expect(DataViewSelection.keep(nil, forIndex: "live-trading-*") == nil)
  }

  @Test func keepComparesTheSavedFormOfThePattern() {
    let pair = view("Pair", "logs-*, metrics-*")
    #expect(DataViewSelection.keep(pair, forIndex: "logs-*,metrics-*") == pair)
  }

  // MARK: - History

  @Test func historyFindsTheOnlyViewWithThePattern() {
    let live = view("Live trading", "live-trading-*")
    let views = [view("Results", "backtesting-results-*"), live]
    #expect(DataViewSelection.view(forHistoryIndex: "live-trading-*", in: views) == live)
    #expect(DataViewSelection.view(forHistoryIndex: "live-logs", in: views) == nil)
  }

  @Test func historyIgnoresPatternsSharedByTwoViews() {
    let views = [view("Live trading", "live-trading-*"), view("Live trading (labels)", "live-trading-*")]
    #expect(DataViewSelection.view(forHistoryIndex: "live-trading-*", in: views) == nil)
  }

  // MARK: - Time field

  @Test func timeFieldIsADateField() throws {
    var live = view("Live trading", "live-trading-*")
    live.timeField = " execution.filledAt "
    let field = try #require(DataViewSelection.timeField(of: live))
    #expect(field.squashedString == "execution.filledAt")
    #expect(field.fieldParts == ["execution", "filledAt"])
    #expect(field.type == "date")

    live.timeField = ""
    #expect(DataViewSelection.timeField(of: live) == nil)
  }

  // MARK: - Labels

  @Test func labelIsTrimmedAndEmptyMeansNone() {
    let labels = ["FILL_PRICE": " Fill price ", "SYMBOL": "  ", "ORDER_ID": ""]
    #expect(DataViewSelection.label(for: "FILL_PRICE", labels: labels) == "Fill price")
    #expect(DataViewSelection.label(for: "SYMBOL", labels: labels) == nil)
    #expect(DataViewSelection.label(for: "ORDER_ID", labels: labels) == nil)
    #expect(DataViewSelection.label(for: "MISSING", labels: labels) == nil)
  }
}
