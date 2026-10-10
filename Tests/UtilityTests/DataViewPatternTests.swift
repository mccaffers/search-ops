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

struct DataViewPatternTests {

  // MARK: - Validate

  @Test func acceptsWildcardsAndCommaLists() {
    #expect(DataViewPattern.validate("logs-*") == nil)
    #expect(DataViewPattern.validate("backtesting-experiments-2026-36") == nil)
    #expect(DataViewPattern.validate("logs-*, metrics-*") == nil)
    #expect(DataViewPattern.validate(".ds-logs-*") == nil)
    #expect(DataViewPattern.validate("*") == nil)
  }

  @Test func rejectsEmptyPatterns() {
    #expect(DataViewPattern.validate("") == .patternEmpty)
    #expect(DataViewPattern.validate("   ") == .patternEmpty)
  }

  @Test func rejectsEmptyListEntries() {
    #expect(DataViewPattern.validate("logs-*,,metrics-*") != nil)
    #expect(DataViewPattern.validate("logs-*,") != nil)
  }

  @Test func rejectsForbiddenCharacters() {
    for pattern in ["logs?", "a/b", "a:b", "a|b", "a#b", "a<b", "a b", "a\\b", "a\"b"] {
      #expect(DataViewPattern.validate(pattern) != nil, "\(pattern)")
    }
  }

  @Test func rejectsExclusions() {
    #expect(DataViewPattern.validate("-logs-*") != nil)
    #expect(DataViewPattern.validate("logs-*,-logs-debug") != nil)
  }

  // MARK: - Matches

  @Test func exactPatternMatchesOnlyThatIndex() {
    #expect(DataViewPattern.matches(pattern: "logs", index: "logs"))
    #expect(!DataViewPattern.matches(pattern: "logs", index: "logs-1"))
    #expect(!DataViewPattern.matches(pattern: "logs", index: "my-logs"))
  }

  @Test func wildcardMatchesAnyRun() {
    #expect(DataViewPattern.matches(pattern: "backtesting-experiments-*", index: "backtesting-experiments-2026-36"))
    #expect(DataViewPattern.matches(pattern: "backtesting-experiments-*", index: "backtesting-experiments-"))
    #expect(!DataViewPattern.matches(pattern: "backtesting-experiments-*", index: "backtesting-results-2026-36"))
    #expect(DataViewPattern.matches(pattern: "*-2026-*", index: "trades-2026-36"))
    #expect(DataViewPattern.matches(pattern: "*", index: "anything"))
  }

  @Test func commaListMatchesAnyPart() {
    #expect(DataViewPattern.matches(pattern: "logs-*, metrics-*", index: "metrics-1"))
    #expect(DataViewPattern.matches(pattern: "logs-*, metrics-*", index: "logs-1"))
    #expect(!DataViewPattern.matches(pattern: "logs-*, metrics-*", index: "traces-1"))
  }

  @Test func regexCharactersAreLiteral() {
    #expect(DataViewPattern.matches(pattern: "logs.app-*", index: "logs.app-1"))
    #expect(!DataViewPattern.matches(pattern: "logs.app-*", index: "logsXapp-1"))
    #expect(DataViewPattern.matches(pattern: "a+b(c)", index: "a+b(c)"))
  }

  // MARK: - Merge fields

  private func field(_ path: String, _ type: String, index: String) -> SquashedFieldsArray {
    let field = SquashedFieldsArray(squashedString: path, fieldParts: path.components(separatedBy: "."))
    field.type = type
    field.index = index
    return field
  }

  @Test func mergeKeepsOneEntryPerField() {
    let merged = DataViewPattern.mergeFields([
      field("@timestamp", "date", index: "a"),
      field("RUN_ID", "text", index: "a"),
      field("@timestamp", "date", index: "b"),
      field("RUN_ID", "text", index: "b"),
      field("duration", "float", index: "b"),
    ])
    #expect(merged.map(\.squashedString) == ["@timestamp", "duration", "RUN_ID"])
    #expect(merged.map(\.type) == ["date", "float", "text"])
    #expect(Set(merged.map(\.id)).count == 3)
    #expect(merged.first?.fieldParts == ["@timestamp"])
  }

  @Test func mergeJoinsConflictingTypes() {
    let merged = DataViewPattern.mergeFields([
      field("status", "text", index: "a"),
      field("status", "keyword", index: "b"),
      field("status", "text", index: "c"),
    ])
    #expect(merged.count == 1)
    #expect(merged.first?.type == "keyword, text")
  }

  // MARK: - Suggest

  @Test func suggestStripsDateAndNumberSuffixes() {
    #expect(DataViewPattern.suggest(from: "backtesting-experiments-2026-36") == "backtesting-experiments-*")
    #expect(DataViewPattern.suggest(from: "logs-2026.10.06") == "logs-*")
    #expect(DataViewPattern.suggest(from: "logs_2026_10_06") == "logs_*")
    #expect(DataViewPattern.suggest(from: "metrics-000001") == "metrics-*")
    #expect(DataViewPattern.suggest(from: ".ds-logs-app-default-2026.10.06-000001") == ".ds-logs-app-default-*")
  }

  @Test func suggestKeepsNamesWithoutASuffix() {
    #expect(DataViewPattern.suggest(from: "trading") == "trading")
    #expect(DataViewPattern.suggest(from: "app-v2") == "app-v2")
    #expect(DataViewPattern.suggest(from: "2026") == "2026")
    #expect(DataViewPattern.suggest(from: "-2026") == "-2026")
  }

  @Test func suggestionMatchesTheIndexItCameFrom() {
    for index in ["backtesting-experiments-2026-36", "logs-2026.10.06", "trading"] {
      #expect(DataViewPattern.matches(pattern: DataViewPattern.suggest(from: index), index: index), "\(index)")
    }
  }

  // MARK: - Sort

  @Test func sortPutsHiddenIndexesLast() {
    let names = [".kibana_1", "trading", ".ds-logs-2026.10.09", "Backtesting", "alerts"]
    #expect(DataViewPattern.sortedIndexNames(names) ==
            ["alerts", "Backtesting", "trading", ".ds-logs-2026.10.09", ".kibana_1"])
  }
}
