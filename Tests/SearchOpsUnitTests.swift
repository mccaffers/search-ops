// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import Testing

@testable import Search_Ops

struct SearchOpsUnitTests {
  
  @Test func testEquality() {
    let field1 = FieldsArray(name: "FieldA")
    let field2 = FieldsArray(name: "FieldA")
    XCTAssertEqual(field1, field2, "FieldsArray instances with the same name should be equal")
  }

  @Test func testIndexFilter_emptyAndWhitespaceQuery() {
    let indices = ["logs-2025", "audit", "metrics"]
    XCTAssertEqual(IndexFilterHelper.filter(indices: indices, query: ""), ["audit", "logs-2025", "metrics"])
    XCTAssertEqual(IndexFilterHelper.filter(indices: indices, query: "   \n"), ["audit", "logs-2025", "metrics"])
  }

  @Test func testIndexFilter_caseInsensitiveSubstring() {
    let indices = ["audit-log", "APP-LOGS", "metrics-2025", "system"]
    let filtered = IndexFilterHelper.filter(indices: indices, query: "log")
    XCTAssertEqual(filtered, ["APP-LOGS", "audit-log"])
  }

  @Test func testIndexFilter_wildcardAsterisk() {
    let indices = ["logs-2025-01", "logs-2024-12", "metrics-logs", "audit"]
    let filteredPrefix = IndexFilterHelper.filter(indices: indices, query: "logs-*")
    XCTAssertEqual(filteredPrefix, ["logs-2024-12", "logs-2025-01"])

    let filteredSuffix = IndexFilterHelper.filter(indices: indices, query: "*logs")
    XCTAssertEqual(filteredSuffix, ["metrics-logs"])
  }

  @Test func testIndexFilter_wildcardQuestionMark() {
    let indices = ["log1", "log2", "log10", "other"]
    let filtered = IndexFilterHelper.filter(indices: indices, query: "log?")
    XCTAssertEqual(filtered, ["log1", "log2"])
  }

  @Test func testIndexFilter_specialCharactersEscaped() {
    let indices = ["app.prod", "appXprod", "data(old)", "data_new"]
    let filteredDot = IndexFilterHelper.filter(indices: indices, query: "app.prod")
    XCTAssertEqual(filteredDot, ["app.prod"])

    let filteredParens = IndexFilterHelper.filter(indices: indices, query: "(old)")
    XCTAssertEqual(filteredParens, ["data(old)"])
  }

  @Test func testIndexFilter_deduplicationAndEmpty() {
    let duplicateIndices = ["audit", "audit", "metrics", "audit"]
    XCTAssertEqual(IndexFilterHelper.filter(indices: duplicateIndices, query: ""), ["audit", "metrics"])

    let emptyIndices: [String] = []
    XCTAssertEqual(IndexFilterHelper.filter(indices: emptyIndices, query: "logs"), [])
  }

  @Test func testIndexFilter_noMatches() {
    let indices = ["logs", "metrics", "traces"]
    XCTAssertEqual(IndexFilterHelper.filter(indices: indices, query: "k8s"), [])
  }

  @Test func testIndexFilter_showAllButton() {
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: ""))
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: "   "))
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: "all"))
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: "_all"))
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: "_ALL"))
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: "*all*"))
    XCTAssertFalse(IndexFilterHelper.showAllButton(query: "logs"))
    XCTAssertFalse(IndexFilterHelper.showAllButton(query: "audit"))
  }

  @Test func testIndexFilter_excludesAllPseudoIndex() {
    let indicesWithAll = ["_all", "audit", "metrics"]
    let filtered = IndexFilterHelper.filter(indices: indicesWithAll, query: "")
    XCTAssertEqual(filtered, ["audit", "metrics"])
    XCTAssertFalse(filtered.contains("_all"))

    let filteredSearch = IndexFilterHelper.filter(indices: indicesWithAll, query: "all")
    XCTAssertEqual(filteredSearch, [])
  }

  @Test func testIndexFilter_totalCount() {
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: []), 1)
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: ["audit", "metrics"]), 3)
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: ["audit", "audit", "metrics"]), 3)
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: ["_all", "audit", "metrics"]), 3)
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: ["_all", "audit", "audit"]), 2)
  }

  @Test func testIndexFilter_consecutiveWildcards() {
    let indices = ["logs-2025-01", "logs-2024-12", "metrics"]
    let filteredDouble = IndexFilterHelper.filter(indices: indices, query: "logs**01")
    XCTAssertEqual(filteredDouble, ["logs-2025-01"])

    let filteredTriple = IndexFilterHelper.filter(indices: indices, query: "***metrics***")
    XCTAssertEqual(filteredTriple, ["metrics"])
  }

  @Test func testIndexFilter_complexPatterns() {
    let indices = ["k8s-prod.logs", "k8s-dev.logs", "k8s-prod.metrics", "other"]
    let filtered = IndexFilterHelper.filter(indices: indices, query: "k8s-*.logs")
    XCTAssertEqual(filtered, ["k8s-dev.logs", "k8s-prod.logs"])

    let singleChar = IndexFilterHelper.filter(indices: ["cat", "cot", "coat", "cut"], query: "c?t")
    XCTAssertEqual(singleChar, ["cat", "cot", "cut"])
  }
}
