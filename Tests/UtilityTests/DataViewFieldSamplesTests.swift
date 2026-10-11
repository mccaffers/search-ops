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

struct DataViewFieldSamplesTests {

  private func response(_ sources: [[String: Any]]) throws -> Data {
    let hits = sources.map { ["_source": $0] }
    return try JSONSerialization.data(withJSONObject: ["hits": ["hits": hits]])
  }

  private func body(_ query: String) throws -> [String: Any] {
    try #require(try JSONSerialization.jsonObject(with: Data(query.utf8)) as? [String: Any])
  }

  // MARK: - Query

  @Test func queryAsksForDocumentsWithTheFieldNewestFirst() throws {
    let json = try body(DataViewFieldSamples.query(field: "completedAttempts.maePoints.p50",
                                                   timeField: "@timestamp", size: 20))
    #expect(json["size"] as? Int == 20)
    let exists = (json["query"] as? [String: Any])?["exists"] as? [String: Any]
    #expect(exists?["field"] as? String == "completedAttempts.maePoints.p50")
    let includes = (json["_source"] as? [String: Any])?["includes"] as? [String]
    #expect(includes == ["completedAttempts.maePoints.p50", "completedAttempts.maePoints"])
    let sort = try #require(json["sort"] as? [[String: Any]])
    let timestamp = try #require(sort.first?["@timestamp"] as? [String: Any])
    #expect(timestamp["order"] as? String == "desc")
    #expect(timestamp["unmapped_type"] as? String == "date")
  }

  @Test func queryWithoutATimeFieldIsUnsorted() throws {
    let json = try body(DataViewFieldSamples.query(field: "RUN_ID", timeField: "", size: 5))
    #expect(json["sort"] == nil)
    #expect((json["_source"] as? [String: Any])?["includes"] as? [String] == ["RUN_ID"])
  }

  // MARK: - Values

  @Test func readsNestedAndDottedKeys() throws {
    let data = try response([
      ["completedAttempts": ["maePoints": ["p50": 1.5]]],
      ["completedAttempts.maePoints.p50": 2.25],
      ["completedAttempts": ["maePoints.p50": 3]],
    ])
    #expect(DataViewFieldSamples.values(from: data, field: "completedAttempts.maePoints.p50", limit: 5)
            == ["1.5", "2.25", "3"])
  }

  @Test func multiFieldFallsBackToItsParent() throws {
    let data = try response([["HOSTNAME": "runner-1"]])
    #expect(DataViewFieldSamples.values(from: data, field: "HOSTNAME.keyword", limit: 5) == ["runner-1"])
  }

  @Test func valuesAreDistinctAndLimited() throws {
    let data = try response([["a": "x"], ["a": "x"], ["a": "y"], ["a": "z"], ["b": "skipped"]])
    #expect(DataViewFieldSamples.values(from: data, field: "a", limit: 2) == ["x", "y"])
  }

  @Test func formatsEachKindOfValue() throws {
    let data = try response([
      ["v": true],
      ["v": 42],
      ["v": NSNull()],
      ["v": ["b": 2, "a": 1]],
      ["v": ["one", "two"]],
    ])
    #expect(DataViewFieldSamples.values(from: data, field: "v", limit: 10)
            == ["true", "42", "null", "{\"a\":1,\"b\":2}", "[\"one\",\"two\"]"])
  }

  @Test func arraysOfObjectsGiveEveryValue() throws {
    let data = try response([["legs": [["id": "A"], ["id": "B"]]]])
    #expect(DataViewFieldSamples.values(from: data, field: "legs.id", limit: 5) == ["[\"A\",\"B\"]"])
  }

  @Test func longValuesAreShortened() throws {
    let data = try response([["v": String(repeating: "x", count: 600)]])
    let value = try #require(DataViewFieldSamples.values(from: data, field: "v", limit: 1).first)
    #expect(value.count == 501)
    #expect(value.hasSuffix("…"))
  }

  @Test func unexpectedResponsesGiveNoValues() {
    #expect(DataViewFieldSamples.values(from: Data("{}".utf8), field: "a", limit: 5).isEmpty)
    #expect(DataViewFieldSamples.values(from: Data("not json".utf8), field: "a", limit: 5).isEmpty)
  }

  // MARK: - Errors

  @Test func httpErrorsIncludeTheClusterReason() {
    let reason = "action [indices:monitor/stats] is unauthorized for user [test] with effective roles [monitoring_user,viewer]"
    let body = #"{"error":{"root_cause":[{"type":"security_exception","reason":"\#(reason)"}],"type":"security_exception","reason":"\#(reason)"},"status":403}"#
    let forbidden = ServerResponse(data: Data(body.utf8))
    forbidden.httpStatus = 403
    #expect(forbidden.httpErrorMessage == "The cluster returned HTTP 403: \(reason)")

    let bare = ServerResponse(data: Data("Forbidden".utf8))
    bare.httpStatus = 403
    #expect(bare.httpErrorMessage == "The cluster returned HTTP 403.")
  }
}
