// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// The most recent distinct values of a field in the search's time period, suggested after `field:`
public enum QueryValueSuggestions {

  public static let limit = 10
  static let aggregationName = "values"
  static let latestName = "latest"

  /// Types a terms aggregation works on as they are
  static let aggregatableTypes: Set<String> = [
    "keyword", "constant_keyword", "wildcard", "version", "ip", "boolean",
    "long", "integer", "short", "byte", "double", "float", "half_float", "scaled_float", "unsigned_long",
    "date", "date_nanos"
  ]
  /// Types whose values are usually aggregated through a `.keyword` multi-field
  static let textTypes: Set<String> = ["text", "match_only_text"]

  /// The field to aggregate on: the field itself, its `.keyword` copy for text, or nil when
  /// it can't be aggregated (eg. geo_point). An unknown type is tried as it is.
  public static func aggregationField(field: String, type: String) -> String? {
    if type.isEmpty || aggregatableTypes.contains(type) {
      return field
    }
    if textTypes.contains(type) {
      return field + ".keyword"
    }
    return nil
  }

  /// The search body: no documents, just the field's values in the time period, newest first
  /// by the latest time each was seen. Without a time field they're the most common instead.
  public static func query(aggregationField: String,
                           timeField: String?,
                           from: String?,
                           to: String?,
                           size: Int = limit) -> String {
    var terms: [String: Any] = ["field": aggregationField, "size": size]
    var aggregation: [String: Any] = [:]
    var body: [String: Any] = ["size": 0]

    if let timeField = timeField, !timeField.isEmpty {
      terms["order"] = [latestName: "desc"]
      aggregation["aggs"] = [latestName: ["max": ["field": timeField]]]

      var range: [String: String] = [:]
      range["gte"] = from
      range["lte"] = to
      if !range.isEmpty {
        body["query"] = ["bool": ["filter": [["range": [timeField: range]]]]]
      }
    }
    aggregation["terms"] = terms
    body["aggs"] = [aggregationName: aggregation]

    guard let data = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys]) else {
      return "{}"
    }
    return String(decoding: data, as: UTF8.self)
  }

  /// The bucket keys in a terms response, in order. key_as_string is used when there is one,
  /// as for booleans, dates and IPs.
  public static func values(from data: Data) -> [String] {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let aggregations = json["aggregations"] as? [String: Any],
          let values = aggregations[aggregationName] as? [String: Any],
          let buckets = values["buckets"] as? [[String: Any]] else {
      return []
    }
    return usable(buckets.compactMap { bucket in
      if let text = bucket["key_as_string"] as? String {
        return text
      }
      return bucket["key"].map(DataViewFieldSamples.format)
    })
  }

  /// Drops values that can't go in the search box: empty, multi-line, or cut short
  static func usable(_ values: [String]) -> [String] {
    values.filter { !$0.isEmpty && $0.count <= 200 && !$0.contains(where: \.isNewline) }
  }

  /// The values to suggest. Falls back to the newest documents' values when the field can't be
  /// aggregated, when a text field has no `.keyword` copy, or when the aggregation fails.
  public static func fetch(serverDetails: HostDetails,
                           index: String,
                           field: String,
                           fieldType: String,
                           timeField: String?,
                           from: Date?,
                           to: Date?) async -> [String] {
    if let aggregationField = aggregationField(field: field, type: fieldType) {
      let endpoint = "/\(index)/_search?ignore_unavailable=true&allow_no_indices=true"
      let body = query(aggregationField: aggregationField,
                       timeField: timeField,
                       from: from.map(DateTools.dateString),
                       to: to.map(DateTools.dateString))
      let response = await Request().invoke(serverDetails: serverDetails, endpoint: endpoint, json: body)
      await Logger.event(response: response, host: serverDetails)

      if response.error == nil, response.httpStatus < 400, let data = response.data {
        let found = values(from: data)
        // A missing .keyword copy aggregates to nothing rather than failing
        if !found.isEmpty || !textTypes.contains(fieldType) {
          return found
        }
      }
    }

    let samples = await DataViewFieldSamples.fetch(serverDetails: serverDetails,
                                                   pattern: index,
                                                   field: field,
                                                   timeField: timeField ?? "",
                                                   limit: limit)
    return usable(samples.values)
  }
}
