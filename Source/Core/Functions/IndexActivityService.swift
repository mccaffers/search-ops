// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public struct DateFieldInfo: Equatable, Hashable {
  public let name: String
  public let isNanos: Bool
  public let isSeconds: Bool
  
  public init(name: String, isNanos: Bool, isSeconds: Bool = false) {
    self.name = name
    self.isNanos = isNanos
    self.isSeconds = isSeconds
  }
}

public struct IndexActivityResult: Equatable {
  public let sortedIndices: [String]
  public let timestamps: [String: Double]
  public let errorMessage: String?
  
  public init(sortedIndices: [String], timestamps: [String: Double], errorMessage: String? = nil) {
    self.sortedIndices = sortedIndices
    self.timestamps = timestamps
    self.errorMessage = errorMessage
  }
}

@available(macOS 13.0, *)
@available(iOS 16.0.0, *)
public class IndexActivityService {
  
  // MARK: - Helpers
  
  public static func escapeJsonString(_ str: String) -> String {
    return str
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
  }
  
  public static func normalizeTimestamp(_ raw: Double, isNanos: Bool, isSeconds: Bool = false) -> Double {
    if isNanos {
      return raw / 1_000_000.0
    } else if isSeconds {
      return raw * 1_000.0
    }
    return raw
  }
  
  // MARK: - Mapping Extraction
  
  public static func parseDateFieldsByIndices(
    from data: Data,
    targetIndices: Set<String>
  ) -> [String: [DateFieldInfo]] {
    guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return [:]
    }
    
    var result: [String: [DateFieldInfo]] = [:]
    
    for (indexName, indexVal) in root {
      if !targetIndices.isEmpty && !targetIndices.contains(indexName) {
        continue
      }
      guard let indexDict = indexVal as? [String: Any] else { continue }
      
      let mappingsDict = (indexDict["mappings"] as? [String: Any]) ?? indexDict
      var fields: [DateFieldInfo] = []
      
      // Modern Elasticsearch (ES 7+): mappings.properties
      if let properties = mappingsDict["properties"] as? [String: Any] {
        extractDateFields(from: properties, prefix: "", into: &fields)
      }
      
      // Legacy Elasticsearch (ES 6 and earlier): mappings.<type>.properties
      for (key, val) in mappingsDict {
        if key != "properties",
           let typeObj = val as? [String: Any],
           let properties = typeObj["properties"] as? [String: Any] {
          extractDateFields(from: properties, prefix: "", into: &fields)
        }
      }
      
      var seen = Set<DateFieldInfo>()
      let uniqueFields = fields.filter { seen.insert($0).inserted }
      result[indexName] = uniqueFields
    }
    
    return result
  }
  
  private static func extractDateFields(
    from properties: [String: Any],
    prefix: String,
    into fields: inout [DateFieldInfo]
  ) {
    for (fieldName, fieldVal) in properties {
      let fullName = prefix.isEmpty ? fieldName : "\(prefix).\(fieldName)"
      guard let dict = fieldVal as? [String: Any] else { continue }
      
      let format = (dict["format"] as? String) ?? ""
      let isSeconds = format.contains("epoch_second") && !format.contains("epoch_millis")
      
      if let type = dict["type"] as? String {
        if type == "date" {
          fields.append(DateFieldInfo(name: fullName, isNanos: false, isSeconds: isSeconds))
        } else if type == "date_nanos" {
          fields.append(DateFieldInfo(name: fullName, isNanos: true, isSeconds: false))
        }
      }
      
      // Handle multi-fields (e.g. fields: { date: { type: "date" } })
      if let subFields = dict["fields"] as? [String: Any] {
        for (subName, subVal) in subFields {
          guard let subDict = subVal as? [String: Any],
                let subType = subDict["type"] as? String else { continue }
          let fullSubName = "\(fullName).\(subName)"
          let subFormat = (subDict["format"] as? String) ?? ""
          let subIsSeconds = subFormat.contains("epoch_second") && !subFormat.contains("epoch_millis")
          if subType == "date" {
            fields.append(DateFieldInfo(name: fullSubName, isNanos: false, isSeconds: subIsSeconds))
          } else if subType == "date_nanos" {
            fields.append(DateFieldInfo(name: fullSubName, isNanos: true, isSeconds: false))
          }
        }
      }
      
      // Handle nested object properties
      if let nestedProps = dict["properties"] as? [String: Any] {
        extractDateFields(from: nestedProps, prefix: fullName, into: &fields)
      }
    }
  }
  
  // MARK: - Date Field Prioritization
  
  public static func selectBestDateField(from fields: [DateFieldInfo]) -> DateFieldInfo? {
    guard !fields.isEmpty else { return nil }
    if fields.count == 1 { return fields[0] }
    
    func rank(for name: String) -> Int {
      let lower = name.lowercased()
      let leaf = lower.split(separator: ".").last.map(String.init) ?? lower
      
      if leaf == "@timestamp" { return 1 }
      if leaf == "timestamp" { return 2 }
      if ["updated_at", "modified_at", "last_modified", "updatedat", "modifiedat", "lastmodified"].contains(leaf) { return 3 }
      if ["created_at", "createdat"].contains(leaf) { return 4 }
      if leaf.contains("date") || leaf.contains("time") { return 5 }
      return 6
    }
    
    return fields.sorted { a, b in
      let rankA = rank(for: a.name)
      let rankB = rank(for: b.name)
      if rankA != rankB {
        return rankA < rankB
      }
      let dotsA = a.name.filter { $0 == "." }.count
      let dotsB = b.name.filter { $0 == "." }.count
      if dotsA != dotsB {
        return dotsA < dotsB
      }
      if a.name.count != b.name.count {
        return a.name.count < b.name.count
      }
      return a.name.localizedStandardCompare(b.name) == .orderedAscending
    }.first
  }
  
  // MARK: - Aggregation Query Building & Parsing
  
  public static func buildBatchedTermsAggQuery(field: String, maxIndices: Int = 65536) -> String {
    let escapedField = escapeJsonString(field)
    return """
    {
      "size": 0,
      "aggs": {
        "by_index": {
          "terms": {
            "field": "_index",
            "size": \(maxIndices)
          },
          "aggs": {
            "max_date": {
              "max": {
                "field": "\(escapedField)"
              }
            }
          }
        }
      }
    }
    """
  }
  
  public static func parseBatchedAggResponse(
    data: Data,
    isNanos: Bool,
    isSeconds: Bool = false
  ) -> [String: Double] {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let aggs = json["aggregations"] as? [String: Any],
          let byIndex = aggs["by_index"] as? [String: Any],
          let buckets = byIndex["buckets"] as? [[String: Any]] else {
      return [:]
    }
    
    var result: [String: Double] = [:]
    for bucket in buckets {
      guard let indexKey = bucket["key"] as? String,
            let maxDate = bucket["max_date"] as? [String: Any],
            let valNum = maxDate["value"] as? NSNumber else {
        continue
      }
      let rawVal = valNum.doubleValue
      guard rawVal.isFinite else { continue }
      let millisVal = normalizeTimestamp(rawVal, isNanos: isNanos, isSeconds: isSeconds)
      result[indexKey] = millisVal
    }
    return result
  }
  
  public static func buildSingleIndexMaxQuery(field: String) -> String {
    let escapedField = escapeJsonString(field)
    return """
    {
      "size": 0,
      "aggs": {
        "max_date": {
          "max": {
            "field": "\(escapedField)"
          }
        }
      }
    }
    """
  }
  
  public static func parseSingleMaxTimestamp(
    data: Data,
    isNanos: Bool,
    isSeconds: Bool = false
  ) -> Double? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let aggs = json["aggregations"] as? [String: Any],
          let maxDate = aggs["max_date"] as? [String: Any],
          let valNum = maxDate["value"] as? NSNumber else {
      return nil
    }
    let rawVal = valNum.doubleValue
    guard rawVal.isFinite else { return nil }
    return normalizeTimestamp(rawVal, isNanos: isNanos, isSeconds: isSeconds)
  }
  
  // MARK: - Deterministic Sorting
  
  public static func sortIndicesByActivity(
    indices: [String],
    timestamps: [String: Double]
  ) -> [String] {
    var seen = Set<String>()
    let uniqueIndices = indices.filter { $0 != "_all" && seen.insert($0).inserted }
    
    return uniqueIndices.sorted { a, b in
      let timeA = timestamps[a]
      let timeB = timestamps[b]
      
      switch (timeA, timeB) {
      case let (.some(tA), .some(tB)):
        if tA != tB {
          return tA > tB
        }
        return a.localizedStandardCompare(b) == .orderedAscending
      case (.some, .none):
        return true
      case (.none, .some):
        return false
      case (.none, .none):
        return a.localizedStandardCompare(b) == .orderedAscending
      }
    }
  }
  
  // MARK: - Request Batching

  /// Elasticsearch refuses request lines over 4 KB (http.max_initial_line_length), so index lists
  /// are kept under this many bytes, leaving room for the endpoint and query string
  public static let maxIndexPathBytes = 3_000

  /// Above this many mapping requests, one filtered /_mapping for the whole cluster is cheaper
  public static let maxScopedMappingRequests = 4

  /// Requests in flight at once while finding the newest documents
  static let maxConcurrentSearches = 4

  /// Only the mapping keys parseDateFieldsByIndices reads. Dynamic templates, analyzers and _meta,
  /// often most of a mapping, are left out
  public static let mappingFilterPath = "*.mappings.**.type,*.mappings.**.format"

  /// Splits index names into comma separated lists that each fit in `maxBytes`, keeping their order.
  /// A name longer than that gets a list of its own
  public static func chunk(_ names: [String], maxBytes: Int = maxIndexPathBytes) -> [[String]] {
    var chunks: [[String]] = []
    var current: [String] = []
    var currentBytes = 0
    for name in names {
      let bytes = name.utf8.count
      // The comma before every name but the first
      if !current.isEmpty && currentBytes + 1 + bytes > maxBytes {
        chunks.append(current)
        current = []
        currentBytes = 0
      }
      currentBytes += current.isEmpty ? bytes : 1 + bytes
      current.append(name)
    }
    if !current.isEmpty {
      chunks.append(current)
    }
    return chunks
  }

  /// The requests that fetch the mappings of `indices`: one per chunk when there are only a few,
  /// otherwise one for the whole cluster, hidden indices included
  public static func mappingEndpoints(for indices: [String], filtered: Bool = true) -> [String] {
    let filter = filtered ? "&filter_path=\(mappingFilterPath)" : ""
    let chunks = chunk(indices)
    if chunks.count > maxScopedMappingRequests {
      return ["/_mapping?expand_wildcards=all\(filter)"]
    }
    return chunks.map { "/\($0.joined(separator: ","))/_mapping?ignore_unavailable=true\(filter)" }
  }

  /// Request only flags failures it couldn't send, a 4xx or 5xx still comes back with a body
  static func succeeded(_ response: ServerResponse) -> Bool {
    response.error == nil && response.data != nil && (200..<300).contains(response.httpStatus)
  }

  static func failureMessage(_ response: ServerResponse, fallback: String) -> String {
    if let error = response.error, !error.message.isEmpty {
      return error.message
    }
    return response.httpStatus == 0 ? fallback : "\(fallback) (HTTP \(response.httpStatus))"
  }

  /// A failure the query caused, eg. one index maps the field differently, which a smaller batch can avoid.
  /// Connection errors, 401/403, 429 and 5xx would fail every request, so they aren't retried
  static func isQueryFailure(_ response: ServerResponse) -> Bool {
    response.error == nil && response.httpStatus == 400
  }

  static let fatalFallback = "Failed to fetch index activity"

  // MARK: - Date Field Cache

  /// The date field picked for an index, nil when it has none
  struct CachedDateField {
    let field: DateFieldInfo?
    let fetched: Date
  }

  /// Mappings rarely change, so sorting again within a few minutes doesn't download them again.
  /// Only indices that aren't cached yet, eg. a data stream's new backing index, are fetched
  public static let dateFieldCacheLifetime: TimeInterval = 300

  @MainActor static var dateFieldCache: [UUID: [String: CachedDateField]] = [:]

  @MainActor public static func clearDateFieldCache() {
    dateFieldCache = [:]
  }

  /// A detached copy keeps its host's id in detachedID, so a copy and its host share a cache
  static func cacheKey(for host: HostDetails) -> UUID {
    host.realm == nil ? host.detachedID : host.id
  }

  // MARK: - Orchestration

  /// Fetches the mappings of `indices` and picks each one's date field. Indices missing from the
  /// response (deleted, or nothing mapped) aren't in the result
  @MainActor
  static func fetchDateFields(
    serverDetails: HostDetails,
    indices: [String],
    request: Request
  ) async -> (fields: [String: DateFieldInfo?], errorMessage: String?) {
    var fields: [String: DateFieldInfo?] = [:]
    var errorMessage: String?
    let targets = Set(indices)

    let filteredEndpoints = mappingEndpoints(for: indices)
    let unfilteredEndpoints = mappingEndpoints(for: indices, filtered: false)
    for (filtered, unfiltered) in zip(filteredEndpoints, unfilteredEndpoints) {
      if Task.isCancelled { break }
      var response = await request.invoke(serverDetails: serverDetails, endpoint: filtered)
      // A server or proxy that won't take filter_path is asked again without it
      if !succeeded(response) && !Task.isCancelled {
        response = await request.invoke(serverDetails: serverDetails, endpoint: unfiltered)
      }
      guard succeeded(response), let data = response.data else {
        errorMessage = failureMessage(response, fallback: "Failed to fetch index mappings")
        continue
      }
      for (index, dateFields) in parseDateFieldsByIndices(from: data, targetIndices: targets) {
        fields.updateValue(selectBestDateField(from: dateFields), forKey: index)
      }
    }
    return (fields, errorMessage)
  }

  /// The newest document's date in each of `indices`, all using `field`. A batch the query fails on,
  /// eg. because one index maps the field differently, is split in half until the index is found,
  /// about 2·log2(n) more requests rather than one per index. Any other failure, eg. expired
  /// credentials or the cluster being down, would fail every request, so it stops and its message comes back as `fatal`
  @MainActor
  static func fetchMaxTimestamps(
    serverDetails: HostDetails,
    indices: [String],
    field: DateFieldInfo,
    request: Request
  ) async -> (timestamps: [String: Double], fatal: String?) {
    guard !indices.isEmpty, !Task.isCancelled else { return ([:], nil) }

    if indices.count == 1 {
      // Queried on its own, an alias's timestamp is keyed by its own name, not its index's
      let index = indices[0]
      let response = await request.invoke(serverDetails: serverDetails,
                                          endpoint: "/\(index)/_search?ignore_unavailable=true",
                                          json: buildSingleIndexMaxQuery(field: field.name))
      guard succeeded(response), let data = response.data else {
        return ([:], isQueryFailure(response) ? nil : failureMessage(response, fallback: fatalFallback))
      }
      guard let timestamp = parseSingleMaxTimestamp(data: data, isNanos: field.isNanos, isSeconds: field.isSeconds) else {
        return ([:], nil)
      }
      return ([index: timestamp], nil)
    }

    let response = await request.invoke(serverDetails: serverDetails,
                                        endpoint: "/\(indices.joined(separator: ","))/_search?ignore_unavailable=true",
                                        json: buildBatchedTermsAggQuery(field: field.name))
    // No buckets is an answer too, those indices have no documents
    if succeeded(response), let data = response.data {
      return (parseBatchedAggResponse(data: data, isNanos: field.isNanos, isSeconds: field.isSeconds), nil)
    }
    guard isQueryFailure(response) else { return ([:], failureMessage(response, fallback: fatalFallback)) }

    let middle = indices.count / 2
    let first = await fetchMaxTimestamps(serverDetails: serverDetails, indices: Array(indices[..<middle]),
                                         field: field, request: request)
    if first.fatal != nil { return first }
    let second = await fetchMaxTimestamps(serverDetails: serverDetails, indices: Array(indices[middle...]),
                                          field: field, request: request)
    return (first.timestamps.merging(second.timestamps) { _, new in new }, second.fatal)
  }

  @MainActor
  public static func fetchIndicesActivity(
    serverDetails: HostDetails,
    indices: [String]
  ) async -> IndexActivityResult {
    var seen = Set<String>()
    let validIndices = indices.filter { $0 != "_all" && seen.insert($0).inserted }
    guard !validIndices.isEmpty else {
      return IndexActivityResult(sortedIndices: [], timestamps: [:])
    }

    func unsorted(_ errorMessage: String? = nil) -> IndexActivityResult {
      IndexActivityResult(sortedIndices: sortIndicesByActivity(indices: validIndices, timestamps: [:]),
                          timestamps: [:],
                          errorMessage: errorMessage)
    }

    if Task.isCancelled { return unsorted() }

    let request = Request()

    // Date fields cached from an earlier sort, then fetch the rest
    let hostKey = cacheKey(for: serverDetails)
    let now = Date()
    var hostCache = dateFieldCache[hostKey] ?? [:]
    var bestFields: [String: DateFieldInfo] = [:]
    var uncached: [String] = []
    for index in validIndices {
      if let entry = hostCache[index], now.timeIntervalSince(entry.fetched) < dateFieldCacheLifetime {
        if let field = entry.field {
          bestFields[index] = field
        }
      } else {
        uncached.append(index)
      }
    }

    if !uncached.isEmpty {
      let fetched = await fetchDateFields(serverDetails: serverDetails, indices: uncached, request: request)
      if Task.isCancelled { return unsorted() }

      if let errorMessage = fetched.errorMessage, fetched.fields.isEmpty, bestFields.isEmpty {
        return unsorted(errorMessage)
      }
      for (index, field) in fetched.fields {
        hostCache[index] = CachedDateField(field: field, fetched: now)
        if let field = field {
          bestFields[index] = field
        }
      }
      dateFieldCache[hostKey] = hostCache
    }

    // One search per field and chunk of indices
    var indicesByField: [DateFieldInfo: [String]] = [:]
    for index in validIndices {
      if let field = bestFields[index] {
        indicesByField[field, default: []].append(index)
      }
    }

    guard !indicesByField.isEmpty else {
      return unsorted("No date fields found in index mappings")
    }

    let jobs = indicesByField.flatMap { field, group in chunk(group).map { (field: field, indices: $0) } }
    var allTimestamps: [String: Double] = [:]
    // The first failure that would fail every request. No more jobs are started after it
    var fatal: String?

    await withTaskGroup(of: (timestamps: [String: Double], fatal: String?).self) { group in
      var next = jobs.startIndex
      func addNextJob() {
        guard next < jobs.endIndex, fatal == nil, !Task.isCancelled else { return }
        let job = jobs[next]
        next += 1
        group.addTask {
          await fetchMaxTimestamps(serverDetails: serverDetails, indices: job.indices, field: job.field, request: request)
        }
      }

      for _ in 0..<maxConcurrentSearches {
        addNextJob()
      }
      for await result in group {
        allTimestamps.merge(result.timestamps) { _, new in new }
        fatal = fatal ?? result.fatal
        addNextJob()
      }
    }

    let sorted = sortIndicesByActivity(indices: validIndices, timestamps: allTimestamps)
    // Some timestamps are still worth sorting by, so a failure is only reported when there are none
    var errorMessage: String?
    if allTimestamps.isEmpty {
      errorMessage = fatal ?? "No document activity found in indices"
    }
    return IndexActivityResult(sortedIndices: sorted, timestamps: allTimestamps, errorMessage: errorMessage)
  }
  
  @MainActor
  public static func fetchIndicesSortedByRecentActivity(
    serverDetails: HostDetails,
    indices: [String]
  ) async -> [String] {
    let result = await fetchIndicesActivity(serverDetails: serverDetails, indices: indices)
    return result.sortedIndices
  }
}
