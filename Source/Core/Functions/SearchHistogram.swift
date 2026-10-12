// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// One bar of the search histogram, the documents whose date falls in start..<end.
public struct HistogramBucket: Identifiable, Equatable, Sendable {
  public init(start: Date, end: Date, count: Int) {
    self.start = start
    self.end = end
    self.count = count
  }

  public var start: Date
  public var end: Date
  public var count: Int
  public var id: Date { start }
}

/// A date histogram bucket size, eg. 30s with the title "30 seconds".
public struct HistogramInterval: Equatable, Sendable {
  public init(seconds: TimeInterval, expression: String, title: String) {
    self.seconds = seconds
    self.expression = expression
    self.title = title
  }

  public var seconds: TimeInterval
  /// The value sent as fixed_interval (or interval on older servers)
  public var expression: String
  /// Read as "<field> per <title>"
  public var title: String
}

/// What to ask the server for: one bucket per interval between from and to.
public struct SearchHistogramRequest: Equatable, Sendable {
  public init(field: String, from: Date, to: Date, interval: HistogramInterval, legacyInterval: Bool) {
    self.field = field
    self.from = from
    self.to = to
    self.interval = interval
    self.legacyInterval = legacyInterval
  }

  public var field: String
  public var from: Date
  public var to: Date
  public var interval: HistogramInterval
  /// Elasticsearch before 7.2 only accepts interval, not fixed_interval
  public var legacyInterval: Bool
}

/// Document counts over the search's time period, drawn above the search results.
public struct SearchHistogram: Equatable, Sendable {
  public init(field: String, from: Date, to: Date, interval: HistogramInterval, buckets: [HistogramBucket]) {
    self.field = field
    self.from = from
    self.to = to
    self.interval = interval
    self.buckets = buckets
  }

  public var field: String
  public var from: Date
  public var to: Date
  public var interval: HistogramInterval
  public var buckets: [HistogramBucket]

  public var totalCount: Int {
    buckets.reduce(0) { $0 + $1.count }
  }

  /// The time period a window dragged between two dates covers, widened to whole bars
  /// and kept inside the histogram's period. Nil when the window covers no bars.
  public func selection(from first: Date, to second: Date) -> HistogramSelection? {
    let lower = min(first, second)
    let upper = max(first, second)
    let selected = buckets.filter { $0.end > lower && $0.start < upper }
    guard let firstBucket = selected.first, let lastBucket = selected.last else { return nil }
    let start = max(firstBucket.start, from)
    let end = min(lastBucket.end, to)
    guard end > start else { return nil }
    return HistogramSelection(from: start, to: end, count: selected.reduce(0) { $0 + $1.count })
  }
}

/// A window dragged across the histogram, snapped to whole bars.
public struct HistogramSelection: Equatable, Sendable {
  public init(from: Date, to: Date, count: Int) {
    self.from = from
    self.to = to
    self.count = count
  }

  public var from: Date
  public var to: Date
  /// Documents in the selected bars
  public var count: Int
}

extension SearchHistogram {

  /// The aggregation's name in the request and response
  public static let aggregationName = "over_time"

  /// The most bars to draw, the interval grows until the time period fits
  public static let maximumBuckets = 80

  /// Bucket sizes a person can read at a glance, smallest first.
  /// fixed_interval has no months or years, so long periods use whole days
  public static let intervals: [HistogramInterval] = [
    HistogramInterval(seconds: 1, expression: "1s", title: "second"),
    HistogramInterval(seconds: 5, expression: "5s", title: "5 seconds"),
    HistogramInterval(seconds: 10, expression: "10s", title: "10 seconds"),
    HistogramInterval(seconds: 15, expression: "15s", title: "15 seconds"),
    HistogramInterval(seconds: 30, expression: "30s", title: "30 seconds"),
    HistogramInterval(seconds: 60, expression: "1m", title: "minute"),
    HistogramInterval(seconds: 5 * 60, expression: "5m", title: "5 minutes"),
    HistogramInterval(seconds: 10 * 60, expression: "10m", title: "10 minutes"),
    HistogramInterval(seconds: 15 * 60, expression: "15m", title: "15 minutes"),
    HistogramInterval(seconds: 30 * 60, expression: "30m", title: "30 minutes"),
    HistogramInterval(seconds: 3600, expression: "1h", title: "hour"),
    HistogramInterval(seconds: 3 * 3600, expression: "3h", title: "3 hours"),
    HistogramInterval(seconds: 6 * 3600, expression: "6h", title: "6 hours"),
    HistogramInterval(seconds: 12 * 3600, expression: "12h", title: "12 hours"),
    HistogramInterval(seconds: 86400, expression: "1d", title: "day"),
    HistogramInterval(seconds: 3 * 86400, expression: "3d", title: "3 days"),
    HistogramInterval(seconds: 7 * 86400, expression: "7d", title: "week"),
    HistogramInterval(seconds: 14 * 86400, expression: "14d", title: "2 weeks"),
    HistogramInterval(seconds: 30 * 86400, expression: "30d", title: "30 days"),
    HistogramInterval(seconds: 90 * 86400, expression: "90d", title: "90 days"),
    HistogramInterval(seconds: 365 * 86400, expression: "365d", title: "365 days")
  ]

  /// The smallest interval that draws the time period in no more than maximumBuckets bars.
  public static func interval(for span: TimeInterval) -> HistogramInterval {
    intervals.first { span / $0.seconds <= Double(maximumBuckets) } ?? intervals[intervals.count - 1]
  }

  /// Only date fields can be bucketed by date, other types make the whole search fail.
  public static func canChart(fieldType: String) -> Bool {
    fieldType == "date" || fieldType == "date_nanos"
  }

  /// The start and end of the filter's time period, or nil when no period is set.
  public static func dateBounds(filterObject: FilterObject, now: Date = .now) -> (from: Date, to: Date)? {
    if let relativeRange = filterObject.relativeRange {
      let seconds = DateTools.calculateSecondsByPeriod(value: relativeRange.value, period: relativeRange.period)
      return (now - seconds, now)
    }
    if let absoluteRange = filterObject.absoluteRange {
      return (absoluteRange.fromNow ? now : absoluteRange.from,
              absoluteRange.toNow ? now : absoluteRange.to)
    }
    return nil
  }

  /// Builds the histogram request for a search, or nil when there's nothing to chart:
  /// no date field, a field that isn't a date, or no time period.
  public static func request(filterObject: FilterObject,
                             fieldType: String?,
                             version: String,
                             now: Date = .now) -> SearchHistogramRequest? {
    guard let field = filterObject.dateField?.squashedString,
          !field.isEmpty,
          let fieldType = fieldType,
          canChart(fieldType: fieldType),
          let bounds = dateBounds(filterObject: filterObject, now: now),
          bounds.to > bounds.from else {
      return nil
    }
    return SearchHistogramRequest(field: field,
                                  from: bounds.from,
                                  to: bounds.to,
                                  interval: interval(for: bounds.to.timeIntervalSince(bounds.from)),
                                  legacyInterval: DevConsoleTemplate.usesLegacyInterval(version: version))
  }

  /// The date_histogram aggregation to add to the search body.
  /// extended_bounds and min_doc_count 0 give empty stretches at either end a bar too.
  static func aggregation(_ request: SearchHistogramRequest,
                                 timeZone: TimeZone = .current) -> [String: GenericQueryBuilder.Aggregation] {
    var histogram = GenericQueryBuilder.DateHistogram(field: request.field)
    if request.legacyInterval {
      histogram.interval = request.interval.expression
    } else {
      histogram.fixed_interval = request.interval.expression
    }
    histogram.min_doc_count = 0
    histogram.extended_bounds = GenericQueryBuilder.Bounds(min: epochMillis(request.from),
                                                           max: epochMillis(request.to))
    histogram.time_zone = timeZone.identifier
    return [aggregationName: GenericQueryBuilder.Aggregation(date_histogram: histogram)]
  }

  /// Reads the buckets out of a search response, or nil when the response has no histogram.
  public static func parse(response: String, request: SearchHistogramRequest) -> SearchHistogram? {
    parse(json: JsonTools.serialiseJson(response), request: request)
  }

  /// Reads the buckets out of a search response that's already been parsed.
  public static func parse(json: [String: Any]?, request: SearchHistogramRequest) -> SearchHistogram? {
    guard let json = json,
          let aggregations = json["aggregations"] as? [String: Any],
          let overTime = aggregations[aggregationName] as? [String: Any],
          let rawBuckets = overTime["buckets"] as? [[String: Any]] else {
      return nil
    }

    // Keys are epoch milliseconds, for date_nanos fields too
    let buckets: [HistogramBucket] = rawBuckets.compactMap { bucket in
      guard let key = bucket["key"] as? NSNumber,
            let count = bucket["doc_count"] as? NSNumber else {
        return nil
      }
      let start = Date(timeIntervalSince1970: key.doubleValue / 1000)
      return HistogramBucket(start: start,
                             end: start.addingTimeInterval(request.interval.seconds),
                             count: count.intValue)
    }

    return SearchHistogram(field: request.field,
                           from: request.from,
                           to: request.to,
                           interval: request.interval,
                           buckets: buckets)
  }

  /// Error types only an aggregation raises
  static let histogramErrorTypes: Set<String> = ["too_many_buckets_exception", "aggregation_execution_exception"]

  /// Whether a failed search failed because of the histogram on `field`, eg. an index pattern where
  /// one index maps the date field as a keyword or text. Those searches are retried without it.
  /// Every cause in the error is checked: the root causes, the caused_by chain and the failed shards.
  public static func isHistogramError(json: [String: Any]?, field: String) -> Bool {
    guard let error = json?["error"] as? [String: Any] else { return false }
    return causes(of: error).contains { isHistogramError(type: $0.type, reason: $0.reason, field: field) }
  }

  /// Whether one error cause came from the histogram. A message that only mentions aggregations isn't
  /// enough, sorting on a text field also fails with "...like aggregations and sorting"
  public static func isHistogramError(type: String?, reason: String?, field: String) -> Bool {
    if let type = type, histogramErrorTypes.contains(type) { return true }
    guard let reason = reason?.lowercased() else { return false }
    if reason.contains("date_histogram") || reason.contains("max_buckets") || reason.contains("[\(aggregationName)]") {
      return true
    }
    // eg. "Fielddata is disabled on text fields by default. Set fielddata=true on [created]..."
    // Only when it names the histogram's own field, not a sort or another aggregation's field
    let quotedField = "[\(field.lowercased())]"
    return reason.contains(quotedField) && (reason.contains("fielddata") || reason.contains("aggregat"))
  }

  /// The type and reason of an error and of everything nested in it.
  static func causes(of error: [String: Any]) -> [(type: String?, reason: String?)] {
    var found: [(type: String?, reason: String?)] = [(error["type"] as? String, error["reason"] as? String)]
    var nested = (error["root_cause"] as? [[String: Any]]) ?? []
    if let causedBy = error["caused_by"] as? [String: Any] {
      nested.append(causedBy)
    }
    for shard in (error["failed_shards"] as? [[String: Any]]) ?? [] {
      if let reason = shard["reason"] as? [String: Any] {
        nested.append(reason)
      }
    }
    for cause in nested {
      found += causes(of: cause)
    }
    return found
  }

  /// Counts for the chart's axis, eg. 2M rather than 2.0E6. Fixed suffixes, as some locales
  /// write millions as a lowercase m, which reads as minutes on a time chart
  public static func shortCount(_ count: Double) -> String {
    let format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...1))
    for (size, suffix) in [(1e9, "B"), (1e6, "M"), (1e3, "K")] where abs(count) >= size {
      return (count / size).formatted(format) + suffix
    }
    return count.formatted(format)
  }

  static func epochMillis(_ date: Date) -> Int64 {
    Int64((date.timeIntervalSince1970 * 1000).rounded())
  }
}
