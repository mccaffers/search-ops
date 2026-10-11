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

struct SearchHistogramTests {

  let now = Date(timeIntervalSince1970: 1_780_000_000)

  func relativeFilter(_ value: Double, _ period: SearchDateTimePeriods, field: String = "@timestamp") -> FilterObject {
    FilterObject(dateField: SquashedFieldsArray(squashedString: field),
                 relativeRange: RelativeRangeFilter(period: period, value: value))
  }

  func encode(_ request: SearchHistogramRequest) throws -> [String: Any] {
    var root = GenericQueryBuilder.Root()
    root.aggs = SearchHistogram.aggregation(request, timeZone: TimeZone(identifier: "Europe/London")!)
    let data = try JSONEncoder().encode(root)
    let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    let aggs = try #require(json["aggs"] as? [String: Any])
    let overTime = try #require(aggs["over_time"] as? [String: Any])
    return try #require(overTime["date_histogram"] as? [String: Any])
  }

  // MARK: - Interval

  @Test func intervalKeepsBarCountReadable() {
    #expect(SearchHistogram.interval(for: 15 * 60).expression == "15s")
    #expect(SearchHistogram.interval(for: 3600).expression == "1m")
    #expect(SearchHistogram.interval(for: 24 * 3600).expression == "30m")
    #expect(SearchHistogram.interval(for: 7 * 86400).expression == "3h")
    #expect(SearchHistogram.interval(for: 30 * 86400).expression == "12h")
    #expect(SearchHistogram.interval(for: 182 * 86400).expression == "3d")
    #expect(SearchHistogram.interval(for: 365 * 86400).expression == "7d")
  }

  @Test func intervalNeverDrawsMoreThanTheMaximumBars() {
    for span in [1.0, 59, 61, 4000, 90_000, 2_000_000, 40_000_000, 150_000_000] {
      let interval = SearchHistogram.interval(for: span)
      #expect(span / interval.seconds <= Double(SearchHistogram.maximumBuckets))
    }
  }

  @Test func intervalForVeryLongPeriodsUsesTheLargestBucket() {
    #expect(SearchHistogram.interval(for: 500 * 365 * 86400).expression == "365d")
  }

  // MARK: - Request

  @Test func requestUsesRelativeRange() throws {
    let request = try #require(SearchHistogram.request(filterObject: relativeFilter(1, .Hours),
                                                       fieldType: "date", version: "8.15.0", now: now))
    #expect(request.field == "@timestamp")
    #expect(request.from == now - 3600)
    #expect(request.to == now)
    #expect(request.interval.expression == "1m")
    #expect(request.legacyInterval == false)
  }

  @Test func requestUsesAbsoluteRange() throws {
    let from = now - 2 * 86400
    let range = AbsoluteDateRangeObject(from: from, to: now - 86400)
    let filter = FilterObject(dateField: SquashedFieldsArray(squashedString: "created"), absoluteRange: range)
    let request = try #require(SearchHistogram.request(filterObject: filter, fieldType: "date_nanos",
                                                       version: "2.11.0", now: now))
    #expect(request.from == from)
    #expect(request.to == now - 86400)
    #expect(request.interval.expression == "30m")
  }

  @Test func requestAbsoluteRangeToNow() throws {
    let range = AbsoluteDateRangeObject(from: now - 600, to: Date(timeIntervalSince1970: 0))
    range.toNow = true
    let filter = FilterObject(dateField: SquashedFieldsArray(squashedString: "created"), absoluteRange: range)
    let request = try #require(SearchHistogram.request(filterObject: filter, fieldType: "date",
                                                       version: "", now: now))
    #expect(request.to == now)
  }

  @Test func requestNeedsDateFieldDateTypeAndPeriod() {
    let noField = FilterObject(relativeRange: RelativeRangeFilter(period: .Hours, value: 1))
    #expect(SearchHistogram.request(filterObject: noField, fieldType: "date", version: "") == nil)

    let noPeriod = FilterObject(dateField: SquashedFieldsArray(squashedString: "@timestamp"))
    #expect(SearchHistogram.request(filterObject: noPeriod, fieldType: "date", version: "") == nil)

    #expect(SearchHistogram.request(filterObject: relativeFilter(1, .Hours), fieldType: "keyword", version: "") == nil)
    #expect(SearchHistogram.request(filterObject: relativeFilter(1, .Hours), fieldType: "long", version: "") == nil)
    #expect(SearchHistogram.request(filterObject: relativeFilter(1, .Hours), fieldType: nil, version: "") == nil)
    #expect(SearchHistogram.request(filterObject: relativeFilter(0, .Hours), fieldType: "date", version: "") == nil)
  }

  @Test func requestUsesLegacyIntervalOnOldElasticsearch() throws {
    let old = try #require(SearchHistogram.request(filterObject: relativeFilter(1, .Hours),
                                                   fieldType: "date", version: "6.8.23", now: now))
    #expect(old.legacyInterval)
    let new = try #require(SearchHistogram.request(filterObject: relativeFilter(1, .Hours),
                                                   fieldType: "date", version: "7.2.0", now: now))
    #expect(new.legacyInterval == false)
  }

  // MARK: - Aggregation JSON

  @Test func aggregationUsesFixedInterval() throws {
    let request = SearchHistogramRequest(field: "@timestamp", from: now - 3600, to: now,
                                         interval: SearchHistogram.interval(for: 3600), legacyInterval: false)
    let histogram = try encode(request)
    #expect(histogram["field"] as? String == "@timestamp")
    #expect(histogram["fixed_interval"] as? String == "1m")
    #expect(histogram["interval"] == nil)
    #expect(histogram["min_doc_count"] as? Int == 0)
    #expect(histogram["time_zone"] as? String == "Europe/London")
    let bounds = try #require(histogram["extended_bounds"] as? [String: Any])
    #expect((bounds["min"] as? NSNumber)?.int64Value == 1_779_996_400_000)
    #expect((bounds["max"] as? NSNumber)?.int64Value == 1_780_000_000_000)
  }

  @Test func aggregationUsesLegacyInterval() throws {
    let request = SearchHistogramRequest(field: "@timestamp", from: now - 3600, to: now,
                                         interval: SearchHistogram.interval(for: 3600), legacyInterval: true)
    let histogram = try encode(request)
    #expect(histogram["interval"] as? String == "1m")
    #expect(histogram["fixed_interval"] == nil)
  }

  @Test func searchWithoutHistogramHasNoAggs() throws {
    let root = GenericQueryBuilder().Create(queries: ["*"], compound: "must", dateField: nil, range: nil)
    let data = try JSONEncoder().encode(root)
    let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(json["aggs"] == nil)
  }

  // MARK: - Parsing

  @Test func parseReadsBuckets() throws {
    let interval = HistogramInterval(seconds: 30, expression: "30s", title: "30 seconds")
    let request = SearchHistogramRequest(field: "@timestamp", from: now - 90, to: now,
                                         interval: interval, legacyInterval: false)
    let response = """
    {"hits":{"total":{"value":7,"relation":"eq"},"hits":[]},
     "aggregations":{"over_time":{"buckets":[
       {"key_as_string":"a","key":1779999900000,"doc_count":4},
       {"key_as_string":"b","key":1779999930000,"doc_count":0},
       {"key_as_string":"c","key":1779999960000,"doc_count":3}
     ]}}}
    """
    let histogram = try #require(SearchHistogram.parse(response: response, request: request))
    #expect(histogram.buckets.count == 3)
    #expect(histogram.buckets[0].start == Date(timeIntervalSince1970: 1_779_999_900))
    #expect(histogram.buckets[0].end == Date(timeIntervalSince1970: 1_779_999_930))
    #expect(histogram.buckets.map(\.count) == [4, 0, 3])
    #expect(histogram.totalCount == 7)
    #expect(histogram.field == "@timestamp")
    #expect(histogram.interval == interval)
  }

  @Test func parseWithoutAggregationsIsNil() {
    let request = SearchHistogramRequest(field: "@timestamp", from: now - 90, to: now,
                                         interval: SearchHistogram.interval(for: 90), legacyInterval: false)
    #expect(SearchHistogram.parse(response: #"{"hits":{"total":0,"hits":[]}}"#, request: request) == nil)
    #expect(SearchHistogram.parse(response: "", request: request) == nil)
  }

  @Test func parseFromJSONMatchesParseFromString() throws {
    let request = SearchHistogramRequest(field: "@timestamp", from: now - 90, to: now,
                                         interval: SearchHistogram.interval(for: 90), legacyInterval: false)
    let response = """
    {"hits":{"total":{"value":5},"hits":[]},
     "aggregations":{"over_time":{"buckets":[{"key":1779999900000,"doc_count":2},{"key":1779999930000,"doc_count":3}]}}}
    """
    let fromString = try #require(SearchHistogram.parse(response: response, request: request))
    let fromJSON = try #require(SearchHistogram.parse(json: JsonTools.serialiseJson(response), request: request))
    #expect(fromJSON.buckets == fromString.buckets)
    #expect(fromJSON.totalCount == fromString.totalCount)
    #expect(SearchHistogram.parse(json: nil, request: request) == nil)
  }

  // MARK: - Selection

  /// Six one-minute bars from now - 360 to now, with counts 1...6
  func minuteHistogram() -> SearchHistogram {
    let interval = HistogramInterval(seconds: 60, expression: "1m", title: "minute")
    let start = now - 360
    let buckets = (0..<6).map { i in
      HistogramBucket(start: start + Double(i) * 60, end: start + Double(i + 1) * 60, count: i + 1)
    }
    return SearchHistogram(field: "@timestamp", from: start, to: now, interval: interval, buckets: buckets)
  }

  @Test func selectionSnapsToWholeBars() throws {
    let histogram = minuteHistogram()
    // From the middle of bar 2 to the middle of bar 4
    let selection = try #require(histogram.selection(from: now - 270, to: now - 130))
    #expect(selection.from == now - 300)
    #expect(selection.to == now - 120)
    #expect(selection.count == 2 + 3 + 4)
  }

  @Test func selectionDraggedBackwardsIsTheSame() {
    let histogram = minuteHistogram()
    #expect(histogram.selection(from: now - 130, to: now - 270) == histogram.selection(from: now - 270, to: now - 130))
  }

  @Test func selectionInsideOneBarCoversThatBar() throws {
    let selection = try #require(minuteHistogram().selection(from: now - 350, to: now - 340))
    #expect(selection.from == now - 360)
    #expect(selection.to == now - 300)
    #expect(selection.count == 1)
  }

  @Test func selectionStaysInsideThePeriod() throws {
    // Bars line up with whole intervals, so the first and last reach past the period
    var histogram = minuteHistogram()
    histogram.from = now - 330
    histogram.to = now - 30
    let selection = try #require(histogram.selection(from: now - 1000, to: now + 1000))
    #expect(selection.from == now - 330)
    #expect(selection.to == now - 30)
    #expect(selection.count == histogram.totalCount)
  }

  @Test func selectionOutsideTheBarsIsNil() {
    let histogram = minuteHistogram()
    #expect(histogram.selection(from: now + 10, to: now + 100) == nil)
    #expect(histogram.selection(from: now - 900, to: now - 400) == nil)
  }

  // MARK: - Zoom history

  @Test func snapshotRestoresRelativeRange() throws {
    let filter = relativeFilter(6, .Months)
    let snapshot = try #require(filter.snapshotDateRange())
    filter.setAbsoluteRange(from: now - 60, to: now)
    #expect(filter.relativeRange == nil)
    #expect(filter.absoluteRange?.from == now - 60)
    #expect(filter.absoluteRange?.to == now)
    #expect(filter.absoluteRange?.toNow == false)

    filter.restore(snapshot)
    #expect(filter.absoluteRange == nil)
    #expect(filter.relativeRange?.value == 6)
    #expect(filter.relativeRange?.period == .Months)
  }

  @Test func snapshotRestoresAbsoluteRange() throws {
    let range = AbsoluteDateRangeObject(from: now - 600, to: now)
    range.toNow = true
    let filter = FilterObject(dateField: SquashedFieldsArray(squashedString: "@timestamp"), absoluteRange: range)
    let snapshot = try #require(filter.snapshotDateRange())

    // The date picker edits the absolute range in place, the snapshot mustn't follow it
    range.from = now - 5
    filter.setAbsoluteRange(from: now - 60, to: now - 30)
    filter.restore(snapshot)
    #expect(filter.relativeRange == nil)
    #expect(filter.absoluteRange?.from == now - 600)
    #expect(filter.absoluteRange?.toNow == true)
  }

  @Test func snapshotWithoutPeriodIsNil() {
    #expect(FilterObject().snapshotDateRange() == nil)
  }

  @Test func snapshotTitles() {
    #expect(DateRangeSnapshot.relative(value: 1, period: .Hours).title == "Last hour")
    #expect(DateRangeSnapshot.relative(value: 6, period: .Months).title == "Last 6 Months")
    #expect(DateRangeSnapshot.absolute(from: now, to: now, fromNow: false, toNow: true).title.hasSuffix("– Now"))
  }

  // MARK: - Axis labels

  @Test func shortCountUsesFixedSuffixes() {
    #expect(SearchHistogram.shortCount(0) == "0")
    #expect(SearchHistogram.shortCount(0.5).hasPrefix("0"))
    #expect(SearchHistogram.shortCount(999) == "999")
    #expect(SearchHistogram.shortCount(1_000) == "1K")
    #expect(SearchHistogram.shortCount(2_000_000) == "2M")
    #expect(SearchHistogram.shortCount(3_000_000_000) == "3B")
    #expect(SearchHistogram.shortCount(1_500_000).hasSuffix("M"))
    #expect(SearchHistogram.shortCount(1_500_000).hasPrefix("1"))
  }

  // MARK: - Failures

  func error(_ rootCause: [String: Any], extra: [String: Any] = [:]) -> [String: Any] {
    var error: [String: Any] = ["root_cause": [rootCause]]
    error.merge(rootCause) { current, _ in current }
    error.merge(extra) { _, new in new }
    return ["error": error, "status": 400]
  }

  @Test func histogramErrorsAreRecognised() {
    #expect(SearchHistogram.isHistogramError(json: error([
      "type": "illegal_argument_exception",
      "reason": "Field [created] of type [keyword] is not supported for aggregation [date_histogram]"
    ]), field: "created"))
    #expect(SearchHistogram.isHistogramError(json: error([
      "type": "too_many_buckets_exception",
      "reason": "Trying to create too many buckets. Must be less than or equal to: [65535]."
    ]), field: "@timestamp"))
    #expect(SearchHistogram.isHistogramError(json: error([
      "type": "illegal_argument_exception",
      "reason": "Fielddata is disabled on text fields by default. Set fielddata=true on [created] in order to load field data"
    ]), field: "created"))
    #expect(SearchHistogram.isHistogramError(json: error([
      "type": "x_content_parse_exception",
      "reason": "[1:120] [over_time] failed to parse field [fixed_interval]"
    ]), field: "@timestamp"))
  }

  @Test func histogramErrorsAreFoundInNestedCauses() {
    // The first root cause is generic, the histogram failure is in a failed shard's caused_by
    let json: [String: Any] = ["error": [
      "type": "search_phase_execution_exception",
      "reason": "all shards failed",
      "root_cause": [["type": "query_shard_exception", "reason": "failed to create query"]],
      "failed_shards": [["shard": 0, "index": "logs-old", "reason": [
        "type": "illegal_argument_exception",
        "reason": "wrapper",
        "caused_by": ["type": "illegal_argument_exception",
                      "reason": "Field [created] of type [keyword] is not supported for aggregation [date_histogram]"]
      ]]]
    ]]
    #expect(SearchHistogram.isHistogramError(json: json, field: "created"))
  }

  @Test func otherErrorsAreNotHistogramErrors() {
    // Sorting on a text field mentions aggregations, but names a different field
    #expect(SearchHistogram.isHistogramError(json: error([
      "type": "illegal_argument_exception",
      "reason": "Text fields are not optimised for operations that require per-document field data like aggregations and sorting, so these operations are disabled by default. Please use a keyword field instead. Alternatively, set fielddata=true on [message] in order to load field data"
    ]), field: "@timestamp") == false)
    #expect(SearchHistogram.isHistogramError(json: error([
      "type": "query_shard_exception", "reason": "Failed to parse query [status:(]"
    ]), field: "@timestamp") == false)
    #expect(SearchHistogram.isHistogramError(json: error([
      "type": "index_not_found_exception", "reason": "no such index [logs]"
    ]), field: "@timestamp") == false)
    #expect(SearchHistogram.isHistogramError(json: error([
      "type": "illegal_argument_exception", "reason": "unknown aggregation type [foo]"
    ]), field: "@timestamp") == false)
    #expect(SearchHistogram.isHistogramError(json: ["took": 1], field: "@timestamp") == false)
    #expect(SearchHistogram.isHistogramError(json: nil, field: "@timestamp") == false)
  }

}
