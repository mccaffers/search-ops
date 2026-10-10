// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// The part a field plays in a Dev console template
public enum TemplateFieldRole: String, CaseIterable, Sendable {
  case date
  case keyword
  case numeric
  case text

  public var title: String {
    switch self {
    case .date: return "Date field"
    case .keyword: return "Keyword field"
    case .numeric: return "Numeric field"
    case .text: return "Text field"
    }
  }

  static let typesByRole: [TemplateFieldRole: Set<String>] = [
    .date: ["date", "date_nanos"],
    .keyword: ["keyword", "constant_keyword", "wildcard", "ip", "boolean"],
    .numeric: ["long", "integer", "short", "byte", "double", "float",
               "half_float", "scaled_float", "unsigned_long"],
    .text: ["text", "match_only_text"]
  ]

  public func accepts(_ type: String) -> Bool {
    TemplateFieldRole.typesByRole[self]?.contains(type) ?? false
  }
}

/// How far back a template's date filter reaches
public enum TemplateTimeRange: String, CaseIterable, Identifiable, Sendable {
  case last15Minutes = "now-15m"
  case lastHour = "now-1h"
  case last4Hours = "now-4h"
  case last24Hours = "now-24h"
  case last7Days = "now-7d"
  case last30Days = "now-30d"
  case last6Months = "now-6M"
  case lastYear = "now-1y"
  case last5Years = "now-5y"

  public static let `default` = TemplateTimeRange.last24Hours

  public var id: String { rawValue }

  /// Elasticsearch date math for the range's start, eg. now-24h
  public var dateMath: String { rawValue }

  /// eg. "24 hours", reads after "the last"
  public var title: String {
    switch self {
    case .last15Minutes: return "15 minutes"
    case .lastHour: return "hour"
    case .last4Hours: return "4 hours"
    case .last24Hours: return "24 hours"
    case .last7Days: return "7 days"
    case .last30Days: return "30 days"
    case .last6Months: return "6 months"
    case .lastYear: return "year"
    case .last5Years: return "5 years"
    }
  }

  /// Date histogram bucket size, keeps the bucket count reasonable for the range.
  /// fixed_interval has no months or years, so long ranges use whole days
  public var histogramInterval: String {
    switch self {
    case .last15Minutes, .lastHour: return "1m"
    case .last4Hours: return "5m"
    case .last24Hours, .last7Days: return "1h"
    case .last30Days, .last6Months: return "1d"
    case .lastYear: return "7d"
    case .last5Years: return "30d"
    }
  }

  var histogramIntervalTitle: String {
    switch histogramInterval {
    case "1m": return "minute"
    case "5m": return "5 minutes"
    case "1d": return "day"
    case "7d": return "week"
    case "30d": return "30 days"
    default: return "hour"
    }
  }
}

public struct TemplateField: Hashable, Sendable {
  public var name: String
  public var type: String

  public init(name: String, type: String) {
    self.name = name
    self.type = type
  }
}

/// Reads a `_mapping` response into a flat list of fields.
/// Unlike `IndexMap`, multi-fields such as `message.keyword` are included,
/// they are usually the only aggregatable copy of a dynamically mapped string
public struct TemplateFieldCatalog {

  public static func parse(_ mappingJSON: String) -> [TemplateField] {
    guard let json = try? JSONSerialization.jsonObject(with: Data(mappingJSON.utf8)) as? [String: Any] else {
      return []
    }

    var fieldsByName = [String: TemplateField]()

    // A pattern such as logs-* returns one entry per index, the fields are merged
    for value in json.values {
      guard let index = value as? [String: Any],
            let mappings = index["mappings"] as? [String: Any] else { continue }

      if let properties = mappings["properties"] as? [String: Any] {
        collect(properties: properties, prefix: "", into: &fieldsByName)
      } else {
        // Elasticsearch 5 & 6 wrap the properties in a mapping type, eg. _doc
        for typeMapping in mappings.values {
          if let properties = (typeMapping as? [String: Any])?["properties"] as? [String: Any] {
            collect(properties: properties, prefix: "", into: &fieldsByName)
          }
        }
      }
    }

    return fieldsByName.values.sorted { $0.name < $1.name }
  }

  private static func collect(properties: [String: Any],
                              prefix: String,
                              into fields: inout [String: TemplateField]) {
    for (key, value) in properties {
      guard let definition = value as? [String: Any] else { continue }
      let name = prefix.isEmpty ? key : "\(prefix).\(key)"
      let type = definition["type"] as? String

      // Nested children need a nested query, so only plain objects are walked
      if let type = type {
        if fields[name] == nil {
          fields[name] = TemplateField(name: name, type: type)
        }
      } else if let children = definition["properties"] as? [String: Any] {
        collect(properties: children, prefix: name, into: &fields)
      }

      if let multiFields = definition["fields"] as? [String: Any] {
        for (subKey, subValue) in multiFields {
          let subName = "\(name).\(subKey)"
          if let subType = (subValue as? [String: Any])?["type"] as? String, fields[subName] == nil {
            fields[subName] = TemplateField(name: subName, type: subType)
          }
        }
      }
    }
  }
}

/// Picks the field a person would most likely choose for each role
public struct TemplateFieldSuggester {

  public static func candidates(for role: TemplateFieldRole, in fields: [TemplateField]) -> [TemplateField] {
    fields
      .filter { role.accepts($0.type) }
      .sorted { lhs, rhs in
        let lhsScore = score(lhs, for: role)
        let rhsScore = score(rhs, for: role)
        if lhsScore != rhsScore { return lhsScore > rhsScore }
        if lhs.name.count != rhs.name.count { return lhs.name.count < rhs.name.count }
        return lhs.name < rhs.name
      }
  }

  public static func suggest(_ role: TemplateFieldRole, in fields: [TemplateField]) -> TemplateField? {
    candidates(for: role, in: fields).first
  }

  public static func suggestAll(in fields: [TemplateField]) -> [TemplateFieldRole: TemplateField] {
    var result = [TemplateFieldRole: TemplateField]()
    for role in TemplateFieldRole.allCases {
      result[role] = suggest(role, in: fields)
    }
    return result
  }

  private static let preferredWords: [TemplateFieldRole: [String]] = [
    .date: ["timestamp", "time", "date", "created", "updated"],
    .keyword: ["status", "level", "severity", "service", "type", "category",
               "host", "env", "environment", "method", "country", "name"],
    .numeric: ["duration", "latency", "took", "bytes", "size", "count",
               "price", "amount", "total", "value"],
    .text: ["message", "msg", "body", "description", "content", "text", "title"]
  ]

  // Identifiers make poor aggregations, every value is unique
  private static let avoidedWords = ["id", "uuid", "guid", "hash", "token", "trace", "span", "session"]

  private static func score(_ field: TemplateField, for role: TemplateFieldRole) -> Int {
    let name = field.name.lowercased()
    var leaf = name.split(separator: ".").last.map(String.init) ?? name
    if leaf == "keyword", let parent = name.split(separator: ".").dropLast().last {
      leaf = String(parent)
    }
    let words = leaf.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)

    var score = 0
    if role == .date && name == "@timestamp" {
      score += 100
    }
    if let preferred = preferredWords[role] {
      for (rank, word) in preferred.enumerated() where words.contains(word) || leaf == word {
        score = max(score, 50 - rank)
      }
      if score == 0, preferred.contains(where: { leaf.contains($0) }) {
        score = 10
      }
    }
    // Also catches camelCase identifiers such as userId
    let originalLeaf = field.name.split(separator: ".").last.map(String.init) ?? field.name
    if words.contains(where: { avoidedWords.contains($0) })
        || originalLeaf.hasSuffix("Id") || originalLeaf.hasSuffix("ID") {
      score -= 60
    }
    // Text fields are usually aggregated through their keyword sub-field
    if role == .keyword && field.type == "keyword" && name.hasSuffix(".keyword") {
      score -= 1
    }
    // Shallow fields are easier to read in a template
    score -= name.filter { $0 == "." }.count
    return score
  }
}

/// The ready made requests offered in the Dev console's templates popup.
/// Every template is a read only GET, so they work with read only mode on
public enum DevConsoleTemplate: String, CaseIterable, Identifiable, Sendable {
  case search
  case count
  case termsAggregation
  case dateHistogram
  case fieldStats

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .search: return "Search"
    case .count: return "Count"
    case .termsAggregation: return "Top values"
    case .dateHistogram: return "Date histogram"
    case .fieldStats: return "Field stats"
    }
  }

  public var summary: String { summary(range: .default) }

  public func summary(range: TemplateTimeRange) -> String {
    switch self {
    case .search: return "Latest documents from the last \(range.title)"
    case .count: return "Number of documents from the last \(range.title)"
    case .termsAggregation: return "Most common values of a keyword field"
    case .dateHistogram: return "Documents per \(range.histogramIntervalTitle) over the last \(range.title)"
    case .fieldStats: return "Min, max, average and percentiles of a number"
    }
  }

  public var systemImage: String {
    switch self {
    case .search: return "magnifyingglass"
    case .count: return "number"
    case .termsAggregation: return "chart.bar.xaxis"
    case .dateHistogram: return "chart.xyaxis.line"
    case .fieldStats: return "function"
    }
  }

  public var requiredRoles: [TemplateFieldRole] {
    switch self {
    case .search, .count: return []
    case .termsAggregation: return [.keyword]
    case .dateHistogram: return [.date]
    case .fieldStats: return [.numeric]
    }
  }

  /// Every role the template reads, required ones first
  public var roles: [TemplateFieldRole] {
    switch self {
    case .search: return [.date, .text]
    case .count: return [.date]
    case .termsAggregation: return [.keyword, .date]
    case .dateHistogram: return [.date]
    case .fieldStats: return [.numeric, .date]
    }
  }

  /// Why the template can't be used, or nil when it can
  public func unavailableReason(fields: [TemplateFieldRole: TemplateField]) -> String? {
    guard let missing = requiredRoles.first(where: { fields[$0] == nil }) else {
      return nil
    }
    switch missing {
    case .date: return "No date fields in the mapping"
    case .keyword: return "No keyword fields in the mapping"
    case .numeric: return "No numeric fields in the mapping"
    case .text: return "No text fields in the mapping"
    }
  }

  /// The request in the Dev console's format, or nil when a required field is missing.
  /// `version` is the host's version number, eg. 8.15.0
  public func render(index: String,
                     fields: [TemplateFieldRole: TemplateField],
                     version: String = "",
                     range: TemplateTimeRange = .default) -> String? {
    guard unavailableReason(fields: fields) == nil else { return nil }

    let index = DevConsoleTemplate.cleanIndex(index)
    let dateFilter = fields[.date].map { rangeFilter(on: $0.name, range: range) }

    switch self {
    case .search:
      var body: [JSONValue] = [.pair("size", .number(20))]
      if let date = fields[.date] {
        body.append(.pair("sort", .array([.object([.pair(date.name, .string("desc"))])])))
      }
      var bool = [JSONValue]()
      if let text = fields[.text] {
        // * matches every document with the field, replace it with your search terms
        bool.append(.pair("must", .array([
          .object([.pair("simple_query_string", .object([
            .pair("query", .string("*")),
            .pair("fields", .array([.string(text.name)]))
          ]))])
        ])))
      }
      if let dateFilter = dateFilter {
        bool.append(.pair("filter", .array([dateFilter])))
      }
      body.append(.pair("query", bool.isEmpty ? matchAll : .object([.pair("bool", .object(bool))])))
      return request("\(index)/_search", body)

    case .count:
      return request("\(index)/_count", [.pair("query", dateFilter ?? matchAll)])

    case .termsAggregation:
      guard let keyword = fields[.keyword] else { return nil }
      var body: [JSONValue] = [.pair("size", .number(0))]
      if let dateFilter = dateFilter {
        body.append(.pair("query", dateFilter))
      }
      body.append(.pair("aggs", .object([
        .pair("top_values", .object([
          .pair("terms", .object([
            .pair("field", .string(keyword.name)),
            .pair("size", .number(10))
          ]))
        ]))
      ])))
      return request("\(index)/_search", body)

    case .dateHistogram:
      guard let date = fields[.date], let dateFilter = dateFilter else { return nil }
      let intervalKey = DevConsoleTemplate.usesLegacyInterval(version: version) ? "interval" : "fixed_interval"
      return request("\(index)/_search", [
        .pair("size", .number(0)),
        .pair("query", dateFilter),
        .pair("aggs", .object([
          .pair("over_time", .object([
            .pair("date_histogram", .object([
              .pair("field", .string(date.name)),
              .pair(intervalKey, .string(range.histogramInterval)),
              .pair("min_doc_count", .number(0))
            ]))
          ]))
        ]))
      ])

    case .fieldStats:
      guard let numeric = fields[.numeric] else { return nil }
      var body: [JSONValue] = [.pair("size", .number(0))]
      if let dateFilter = dateFilter {
        body.append(.pair("query", dateFilter))
      }
      body.append(.pair("aggs", .object([
        .pair("stats", .object([
          .pair("stats", .object([.pair("field", .string(numeric.name))]))
        ])),
        .pair("percentiles", .object([
          .pair("percentiles", .object([
            .pair("field", .string(numeric.name)),
            .pair("percents", .array([.number(50), .number(95), .number(99)]))
          ]))
        ]))
      ])))
      return request("\(index)/_search", body)
    }
  }

  /// fixed_interval arrived in Elasticsearch 7.2, older versions only accept interval.
  /// OpenSearch reports 1.x and later, which all accept fixed_interval
  public static func usesLegacyInterval(version: String) -> Bool {
    let parts = version.split(separator: ".").compactMap { Int($0) }
    guard let major = parts.first else { return false }
    let minor = parts.count > 1 ? parts[1] : 0
    return major == 5 || major == 6 || (major == 7 && minor < 2)
  }

  /// The index part of a Dev console path, eg. logs-* from GET /logs-*/_search.
  /// Returns nil for API paths such as /_cat/indices
  public static func index(fromRequestText text: String) -> String? {
    guard case .success(let request) = DevConsoleParser.parse(text) else { return nil }
    let path = request.path.split(separator: "?").first.map(String.init) ?? request.path
    guard let first = path.split(separator: "/").first.map(String.init),
          !first.hasPrefix("_"), !first.isEmpty else {
      return nil
    }
    return first
  }

  static func cleanIndex(_ index: String) -> String {
    let trimmed = index.trimmingCharacters(in: CharacterSet(charactersIn: "/").union(.whitespaces))
    return trimmed.isEmpty ? "_all" : trimmed
  }

  private var matchAll: JSONValue {
    .object([.pair("match_all", .object([]))])
  }

  private func rangeFilter(on field: String, range: TemplateTimeRange) -> JSONValue {
    .object([.pair("range", .object([
      .pair(field, .object([.pair("gte", .string(range.dateMath))]))
    ]))])
  }

  private func request(_ path: String, _ body: [JSONValue]) -> String {
    "GET /\(path)\n" + JSONValue.object(body).rendered()
  }
}

/// A minimal ordered JSON writer, so templates keep a readable key order
indirect enum JSONValue {
  case object([JSONValue])
  case pair(String, JSONValue)
  case array([JSONValue])
  case string(String)
  case number(Int)

  func rendered(depth: Int = 0) -> String {
    let indent = String(repeating: "  ", count: depth + 1)
    let closingIndent = String(repeating: "  ", count: depth)

    switch self {
    case .object(let members):
      guard !members.isEmpty else { return "{}" }
      let lines = members.map { indent + $0.rendered(depth: depth + 1) }
      return "{\n" + lines.joined(separator: ",\n") + "\n" + closingIndent + "}"
    case .pair(let key, let value):
      // The pair is already indented by its object, its value closes at the same level
      return JSONValue.quote(key) + ": " + value.rendered(depth: depth)
    case .array(let items):
      guard !items.isEmpty else { return "[]" }
      // Short arrays of scalars stay on one line, eg. [50, 95, 99]
      if items.allSatisfy({ $0.isScalar }) {
        return "[" + items.map { $0.rendered() }.joined(separator: ", ") + "]"
      }
      let lines = items.map { indent + $0.rendered(depth: depth + 1) }
      return "[\n" + lines.joined(separator: ",\n") + "\n" + closingIndent + "]"
    case .string(let value):
      return JSONValue.quote(value)
    case .number(let value):
      return String(value)
    }
  }

  private var isScalar: Bool {
    switch self {
    case .string, .number: return true
    default: return false
    }
  }

  static func quote(_ value: String) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]),
          let quoted = String(data: data, encoding: .utf8) else {
      return "\"\(value)\""
    }
    // JSONSerialization escapes forward slashes, which are valid unescaped
    return quoted.replacingOccurrences(of: "\\/", with: "/")
  }
}

@MainActor
public struct DevConsoleTemplateService {

  public enum LoadError: Error, Equatable, LocalizedError {
    case request(String)
    case noFields

    public var errorDescription: String? {
      switch self {
      case .request(let message): return message
      case .noFields: return "The mapping has no fields, the index may be empty"
      }
    }
  }

  /// Non-hidden indices and aliases on the host, sorted by name
  public static func loadIndices(host: HostDetails) async -> [String] {
    let response = await Indicies.listIndexes(serverDetails: host)
    guard let parsed = response.parsed else { return [] }
    return Results.getIndexArray(parsed).data.sorted()
  }

  public static func loadFields(host: HostDetails, index: String) async -> Result<[TemplateField], LoadError> {
    let endpoint = "/\(DevConsoleTemplate.cleanIndex(index))/_mapping"
    let clock = ContinuousClock()
    let start = clock.now
    let response = await Request().invoke(serverDetails: host, endpoint: endpoint)
    response.duration = clock.now - start

    let body = String(decoding: response.data ?? Data(), as: UTF8.self)
    let fields = response.error == nil ? TemplateFieldCatalog.parse(body) : []
    if response.data != nil {
      response.parsed = body
    }
    Logger.event(response: response,
                 index: index,
                 host: host,
                 hitCount: fields.count,
                 source: LogEvent.devConsoleSource)

    if let error = response.error {
      return .failure(.request(error.message))
    }

    if let error = Results.getIndexArray(body).error {
      return .failure(.request(error))
    }

    return fields.isEmpty ? .failure(.noFields) : .success(fields)
  }
}
