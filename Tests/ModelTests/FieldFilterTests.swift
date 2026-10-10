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

struct FieldFilterTests {

  // MARK: - Making a filter from a document value

  @Test func makesAFilterForASingleValue() throws {
    let filter = try #require(FieldFilter.make(field: "hostname", values: ["live-trading"]))
    #expect(filter.field == "hostname")
    #expect(filter.value == "live-trading")
    #expect(!filter.negated)
    #expect(!filter.disabled)
  }

  @Test func makesANegatedFilter() throws {
    let filter = try #require(FieldFilter.make(field: "env", values: ["demo"], negated: true))
    #expect(filter.negated)
  }

  @Test func acceptsAPlainString() {
    #expect(FieldFilter.make(field: "env", values: "demo")?.value == "demo")
  }

  @Test func makesNoFilterWithoutASingleValue() {
    #expect(FieldFilter.make(field: "tags", values: ["a", "b"]) == nil)
    #expect(FieldFilter.make(field: "tags", values: [String]()) == nil)
    #expect(FieldFilter.make(field: "tags", values: ["  "]) == nil)
    #expect(FieldFilter.make(field: "tags", values: 5) == nil)
  }

  @Test func shortensLongValuesInTheMiddle() {
    #expect(FieldFilter.shortened("live-trading") == "live-trading")
    let long = String(repeating: "a", count: 30) + String(repeating: "b", count: 30)
    let short = FieldFilter.shortened(long, limit: 11)
    #expect(short == "aaaaa…bbbbb")
    #expect(FieldFilter.shortened(long).count == 40)
  }

  // MARK: - Changing the filters

  @Test func addingAppendsANewFilter() {
    let filters = [FieldFilter]()
      .adding(field: "hostname", value: "live-trading", negated: false)
      .adding(field: "env", value: "demo", negated: true)
    #expect(filters.map(\.field) == ["hostname", "env"])
    #expect(filters.map(\.negated) == [false, true])
  }

  @Test func addingTheSameValueAgainUpdatesTheFilterInPlace() throws {
    var filters = [FieldFilter]().adding(field: "env", value: "demo", negated: false)
    let id = try #require(filters.first?.id)
    filters = filters.updating(id) { $0.disabled = true }

    filters = filters.adding(field: "env", value: "demo", negated: true)

    #expect(filters.count == 1)
    #expect(filters.first?.id == id)
    #expect(filters.first?.negated == true)
    #expect(filters.first?.disabled == false)
  }

  @Test func filterObjectChangesFilters() throws {
    let filterObject = FilterObject()
    filterObject.addFieldFilter(field: "env", value: "demo")
    filterObject.addFieldFilter(field: "hostname", value: "live-trading")
    let id = try #require(filterObject.fieldFilters.first?.id)

    filterObject.toggleFieldFilterNegated(id)
    #expect(filterObject.fieldFilters.first?.negated == true)

    filterObject.toggleFieldFilterDisabled(id)
    #expect(filterObject.fieldFilters.first?.disabled == true)

    filterObject.removeFieldFilter(id)
    #expect(filterObject.fieldFilters.map(\.field) == ["hostname"])

    filterObject.clearFieldFilters()
    #expect(filterObject.fieldFilters.isEmpty)
  }

  @Test func clearingTheFilterObjectClearsFieldFilters() {
    let filterObject = FilterObject()
    filterObject.addFieldFilter(field: "env", value: "demo")
    filterObject.clear()
    #expect(filterObject.fieldFilters.isEmpty)
  }

  @Test func resettingIndexFiltersKeepsFieldFilters() {
    // The date pickers reset these too, so the chips must survive it
    let filterObject = FilterObject()
    filterObject.addFieldFilter(field: "env", value: "demo")
    filterObject.resetIndexSpecificFilters()
    #expect(filterObject.fieldFilters.count == 1)
  }

  @Test func comparesFiltersInAnyOrder() {
    let a = [FieldFilter(field: "env", value: "demo"), FieldFilter(field: "host", value: "x", negated: true)]
    let b = [FieldFilter(field: "host", value: "x", negated: true), FieldFilter(field: "env", value: "demo")]
    #expect(a.hasSameFilters(as: b))
    #expect(!a.hasSameFilters(as: [a[0]]))
    #expect(!a.hasSameFilters(as: [a[0], FieldFilter(field: "host", value: "x")]))
  }

  @Test func looksUpFilteredValuesByFieldAndValue() {
    let filters = [FieldFilter(field: "env", value: "demo", negated: true),
                   FieldFilter(field: "hostname", value: "live-trading"),
                   FieldFilter(field: "event", value: "stats", disabled: true)]
    let keys = filters.enabledValues
    #expect(keys[FieldFilterKey(field: "env", value: "demo")] == true)
    #expect(keys[FieldFilterKey(field: "hostname", value: "live-trading")] == false)
    #expect(keys[FieldFilterKey(field: "event", value: "stats")] == nil)
    #expect(keys[FieldFilterKey(field: "env", value: "live")] == nil)
  }

  // MARK: - The search request

  func encode(_ root: GenericQueryBuilder.Root) throws -> [String: Any] {
    let data = try JSONEncoder().encode(root)
    return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  func boolQuery(_ filters: [FieldFilter]) throws -> [String: Any] {
    let root = GenericQueryBuilder().Create(queries: ["*"], compound: "must", dateField: nil, range: nil,
                                            filters: filters)
    let json = try encode(root)
    let query = try #require(json["query"] as? [String: Any])
    return try #require(query["bool"] as? [String: Any])
  }

  @Test func leavesTheRequestUnchangedWithoutFilters() throws {
    let bool = try boolQuery([])
    #expect(bool["filter"] == nil)
    #expect(bool["must_not"] == nil)
    #expect((bool["must"] as? [Any])?.count == 1)
  }

  @Test func sendsFiltersAsPhraseMatches() throws {
    let bool = try boolQuery([FieldFilter(field: "hostname", value: "live-trading"),
                              FieldFilter(field: "bookRemoved", value: "198")])
    let filter = try #require(bool["filter"] as? [[String: [String: String]]])
    #expect(filter == [["match_phrase": ["hostname": "live-trading"]],
                       ["match_phrase": ["bookRemoved": "198"]]])
    #expect(bool["must_not"] == nil)
  }

  @Test func sendsNegatedFiltersAsMustNot() throws {
    let bool = try boolQuery([FieldFilter(field: "env", value: "demo", negated: true)])
    let mustNot = try #require(bool["must_not"] as? [[String: [String: String]]])
    #expect(mustNot == [["match_phrase": ["env": "demo"]]])
    #expect(bool["filter"] == nil)
  }

  @Test func leavesOutDisabledFilters() throws {
    let bool = try boolQuery([FieldFilter(field: "env", value: "demo", disabled: true),
                              FieldFilter(field: "host", value: "x", negated: true, disabled: true),
                              FieldFilter(field: "event", value: "stats")])
    let filter = try #require(bool["filter"] as? [[String: [String: String]]])
    #expect(filter == [["match_phrase": ["event": "stats"]]])
    #expect(bool["must_not"] == nil)
  }

  @Test func keepsQueryStringAndDateRangeWithFilters() throws {
    let range = GenericQueryBuilder.Date(lte: "now", gte: "2026-10-09T00:00:00Z")
    let root = GenericQueryBuilder().Create(queries: ["error"], compound: "must", dateField: "@timestamp",
                                            range: range,
                                            filters: [FieldFilter(field: "env", value: "demo")])
    #expect(root.query?.bool?.must?.count == 2)
    #expect(root.query?.bool?.must?.first?.query_string?.query == "error")
    #expect(root.query?.bool?.filter?.count == 1)
  }
}
