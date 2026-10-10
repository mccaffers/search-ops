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

struct QueryValueSuggestionsTests {

  func json(_ text: String) throws -> [String: Any] {
    try #require(try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
  }

  // MARK: - Aggregation field

  @Test func aggregatesKeywordsNumbersAndUnknownTypesAsTheyAre() {
    for type in ["keyword", "long", "ip", "boolean", "date", ""] {
      #expect(QueryValueSuggestions.aggregationField(field: "env", type: type) == "env", "\(type)")
    }
  }

  @Test func aggregatesTextThroughItsKeywordCopy() {
    #expect(QueryValueSuggestions.aggregationField(field: "message", type: "text") == "message.keyword")
    #expect(QueryValueSuggestions.aggregationField(field: "message", type: "match_only_text") == "message.keyword")
  }

  @Test func doesNotAggregateOtherTypes() {
    for type in ["geo_point", "object", "nested", "binary", "dense_vector"] {
      #expect(QueryValueSuggestions.aggregationField(field: "x", type: type) == nil, "\(type)")
    }
  }

  // MARK: - Query

  @Test func asksForTheNewestValuesInTheTimePeriod() throws {
    let body = try json(QueryValueSuggestions.query(aggregationField: "env",
                                                    timeField: "@timestamp",
                                                    from: "2026-10-09T18:11:00+0100",
                                                    to: "2026-10-09T19:11:00+0100"))
    #expect(body["size"] as? Int == 0)

    let filter = try #require(((body["query"] as? [String: Any])?["bool"] as? [String: Any])?["filter"] as? [[String: Any]])
    let range = try #require((filter.first?["range"] as? [String: Any])?["@timestamp"] as? [String: String])
    #expect(range == ["gte": "2026-10-09T18:11:00+0100", "lte": "2026-10-09T19:11:00+0100"])

    let values = try #require((body["aggs"] as? [String: Any])?["values"] as? [String: Any])
    let terms = try #require(values["terms"] as? [String: Any])
    #expect(terms["field"] as? String == "env")
    #expect(terms["size"] as? Int == 10)
    #expect(terms["order"] as? [String: String] == ["latest": "desc"])
    let latest = try #require((values["aggs"] as? [String: Any])?["latest"] as? [String: Any])
    #expect((latest["max"] as? [String: String]) == ["field": "@timestamp"])
  }

  @Test func usesTheMostCommonValuesWithoutATimeField() throws {
    let body = try json(QueryValueSuggestions.query(aggregationField: "env", timeField: nil, from: nil, to: nil))
    #expect(body["query"] == nil)
    let values = try #require((body["aggs"] as? [String: Any])?["values"] as? [String: Any])
    #expect(values["aggs"] == nil)
    #expect((values["terms"] as? [String: Any])?["order"] == nil)
  }

  @Test func leavesTheRangeOutWithoutATimePeriod() throws {
    let body = try json(QueryValueSuggestions.query(aggregationField: "env", timeField: "@timestamp", from: nil, to: nil))
    #expect(body["query"] == nil)
    let values = try #require((body["aggs"] as? [String: Any])?["values"] as? [String: Any])
    #expect(values["aggs"] != nil)
  }

  // MARK: - Parse

  @Test func readsBucketKeysInOrder() {
    let response = """
    {"aggregations": {"values": {"buckets": [
      {"key": "prod", "doc_count": 3},
      {"key": 200, "doc_count": 2},
      {"key": 1, "key_as_string": "true", "doc_count": 1},
      {"key": 3.5, "doc_count": 1},
      {"key": "", "doc_count": 1},
      {"key": "two\\nlines", "doc_count": 1}
    ]}}}
    """
    #expect(QueryValueSuggestions.values(from: Data(response.utf8)) == ["prod", "200", "true", "3.5"])
  }

  @Test func readsNothingFromAnUnexpectedResponse() {
    #expect(QueryValueSuggestions.values(from: Data("{}".utf8)).isEmpty)
    #expect(QueryValueSuggestions.values(from: Data("not json".utf8)).isEmpty)
    #expect(QueryValueSuggestions.values(from: Data(#"{"aggregations": {"values": {}}}"#.utf8)).isEmpty)
  }

  @Test func dropsValuesTooLongToType() {
    let long = String(repeating: "a", count: 201)
    #expect(QueryValueSuggestions.usable(["ok", long]) == ["ok"])
  }
}
