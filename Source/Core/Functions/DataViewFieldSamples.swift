// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// A few recent values of one field, to show what it holds while labelling it
public enum DataViewFieldSamples {

  /// The search body: the latest documents that have the field, with only that field (and its parent,
  /// for multi-fields such as `name.keyword` that aren't in `_source`) returned.
  public static func query(field: String, timeField: String, size: Int) -> String {
    var includes = [field]
    if let parent = parentPath(of: field) {
      includes.append(parent)
    }
    var body: [String: Any] = [
      "size": size,
      "query": ["exists": ["field": field]],
      "_source": ["includes": includes]
    ]
    if !timeField.isEmpty {
      // unmapped_type keeps indexes without the time field from failing the search
      body["sort"] = [[timeField: ["order": "desc", "unmapped_type": "date"]]]
    }
    guard let data = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys]) else {
      return "{}"
    }
    return String(decoding: data, as: UTF8.self)
  }

  /// Distinct values of the field in a search response, in document order, at most `limit`
  public static func values(from data: Data, field: String, limit: Int) -> [String] {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let hits = (json["hits"] as? [String: Any])?["hits"] as? [[String: Any]] else {
      return []
    }

    let parts = field.components(separatedBy: ".")
    var seen = Set<String>()
    var result: [String] = []
    for hit in hits {
      guard let source = hit["_source"] as? [String: Any] else { continue }
      var found = value(at: parts, in: source)
      // A multi-field's value is its parent's, eg. name.keyword holds name
      if found.isEmpty, parts.count > 1 {
        found = value(at: Array(parts.dropLast()), in: source)
      }
      guard !found.isEmpty else { continue }
      let text = format(found.count == 1 ? found[0] : found)
      if seen.insert(text).inserted {
        result.append(text)
        if result.count == limit { break }
      }
    }
    return result
  }

  public static func fetch(serverDetails: HostDetails,
                           pattern: String,
                           field: String,
                           timeField: String,
                           limit: Int = 5) async -> (values: [String], error: ResponseError?) {
    let endpoint = "/\(pattern)/_search?ignore_unavailable=true&allow_no_indices=true"
    let body = query(field: field, timeField: timeField, size: limit * 4)
    let response = await Request().invoke(serverDetails: serverDetails, endpoint: endpoint, json: body)

    await Logger.event(response: response, host: serverDetails)

    if let error = response.error {
      return ([], error)
    }
    if response.httpStatus >= 400 {
      return ([], ResponseError(title: "Couldn't load values",
                                message: "The cluster returned HTTP \(response.httpStatus).",
                                type: .warn))
    }
    guard let data = response.data else {
      return ([], nil)
    }
    return (values(from: data, field: field, limit: limit), nil)
  }

  static func parentPath(of field: String) -> String? {
    let parts = field.components(separatedBy: ".")
    guard parts.count > 1 else { return nil }
    return parts.dropLast().joined(separator: ".")
  }

  /// Every value at the path. Objects may be nested or use dotted keys, eg. {"a": {"b": 1}} or {"a.b": 1},
  /// and arrays of objects give one value per element.
  static func value(at parts: [String], in object: Any) -> [Any] {
    guard !parts.isEmpty else { return [object] }

    if let array = object as? [Any] {
      return array.flatMap { value(at: parts, in: $0) }
    }
    guard let dictionary = object as? [String: Any] else { return [] }

    var results: [Any] = []
    for length in 1...parts.count {
      let key = parts[0..<length].joined(separator: ".")
      guard let next = dictionary[key] else { continue }
      if length == parts.count {
        if let array = next as? [Any] {
          results.append(contentsOf: array)
        } else {
          results.append(next)
        }
      } else {
        results.append(contentsOf: value(at: Array(parts[length...]), in: next))
      }
    }
    return results
  }

  static func format(_ value: Any) -> String {
    let text: String
    switch value {
    case let string as String:
      text = string
    case is NSNull:
      text = "null"
    case let number as NSNumber:
      // NSNumber also holds booleans
      text = CFGetTypeID(number) == CFBooleanGetTypeID() ? (number.boolValue ? "true" : "false") : number.stringValue
    default:
      if JSONSerialization.isValidJSONObject(value),
         let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) {
        text = String(decoding: data, as: UTF8.self)
      } else {
        text = String(describing: value)
      }
    }
    return text.count > 500 ? String(text.prefix(500)) + "…" : text
  }
}
