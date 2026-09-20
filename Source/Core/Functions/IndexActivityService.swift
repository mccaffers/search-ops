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
  
  // MARK: - Orchestration
  
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
    
    if Task.isCancelled {
      let sorted = sortIndicesByActivity(indices: validIndices, timestamps: [:])
      return IndexActivityResult(sortedIndices: sorted, timestamps: [:])
    }
    
    let request = Request()
    let mappingResponse = await request.invoke(serverDetails: serverDetails, endpoint: "/_mapping")
    
    if Task.isCancelled {
      let sorted = sortIndicesByActivity(indices: validIndices, timestamps: [:])
      return IndexActivityResult(sortedIndices: sorted, timestamps: [:])
    }
    
    if let error = mappingResponse.error {
      let errorMsg = error.message.isEmpty ? "Failed to fetch index mappings" : error.message
      let sorted = sortIndicesByActivity(indices: validIndices, timestamps: [:])
      return IndexActivityResult(sortedIndices: sorted, timestamps: [:], errorMessage: errorMsg)
    }
    
    guard let mappingData = mappingResponse.data else {
      let sorted = sortIndicesByActivity(indices: validIndices, timestamps: [:])
      return IndexActivityResult(sortedIndices: sorted, timestamps: [:], errorMessage: "No mapping data received")
    }
    
    let targetSet = Set(validIndices)
    let dateFieldsByIndex = parseDateFieldsByIndices(from: mappingData, targetIndices: targetSet)
    
    var indicesByField: [DateFieldInfo: [String]] = [:]
    for index in validIndices {
      if let fields = dateFieldsByIndex[index], let bestField = selectBestDateField(from: fields) {
        indicesByField[bestField, default: []].append(index)
      }
    }
    
    guard !indicesByField.isEmpty else {
      let sorted = sortIndicesByActivity(indices: validIndices, timestamps: [:])
      return IndexActivityResult(sortedIndices: sorted, timestamps: [:], errorMessage: "No date fields found in index mappings")
    }
    
    var allTimestamps: [String: Double] = [:]
    
    for (fieldInfo, groupIndices) in indicesByField {
      if Task.isCancelled { break }
      
      let chunkSize = 50
      for chunkStart in stride(from: 0, to: groupIndices.count, by: chunkSize) {
        if Task.isCancelled { break }
        let chunkEnd = min(chunkStart + chunkSize, groupIndices.count)
        let chunk = Array(groupIndices[chunkStart..<chunkEnd])
        
        let joinedIndices = chunk.joined(separator: ",")
        let endpoint = "/\(joinedIndices)/_search"
        let queryBody = buildBatchedTermsAggQuery(field: fieldInfo.name)
        
        let searchResponse = await request.invoke(
          serverDetails: serverDetails,
          endpoint: endpoint,
          json: queryBody
        )
        
        if Task.isCancelled { break }
        
        if searchResponse.error == nil, let data = searchResponse.data {
          let chunkTimestamps = parseBatchedAggResponse(
            data: data,
            isNanos: fieldInfo.isNanos,
            isSeconds: fieldInfo.isSeconds
          )
          if !chunkTimestamps.isEmpty {
            allTimestamps.merge(chunkTimestamps) { (_, new) in new }
            continue
          }
        }
        
        // Fallback: If batched search fails or returned no buckets, query indices individually with up to 4 concurrent workers
        let singleQueryBody = buildSingleIndexMaxQuery(field: fieldInfo.name)
        await withTaskGroup(of: (String, Double?).self) { group in
          var iterator = chunk.makeIterator()
          for _ in 0..<min(4, chunk.count) {
            if let nextIdx = iterator.next() {
              group.addTask {
                if Task.isCancelled { return (nextIdx, nil) }
                let singleRes = await request.invoke(
                  serverDetails: serverDetails,
                  endpoint: "/\(nextIdx)/_search",
                  json: singleQueryBody
                )
                if let singleData = singleRes.data {
                  let ts = parseSingleMaxTimestamp(
                    data: singleData,
                    isNanos: fieldInfo.isNanos,
                    isSeconds: fieldInfo.isSeconds
                  )
                  return (nextIdx, ts)
                }
                return (nextIdx, nil)
              }
            }
          }
          
          for await (idx, ts) in group {
            if let ts = ts {
              allTimestamps[idx] = ts
            }
            if !Task.isCancelled, let nextIdx = iterator.next() {
              group.addTask {
                if Task.isCancelled { return (nextIdx, nil) }
                let singleRes = await request.invoke(
                  serverDetails: serverDetails,
                  endpoint: "/\(nextIdx)/_search",
                  json: singleQueryBody
                )
                if let singleData = singleRes.data {
                  let ts = parseSingleMaxTimestamp(
                    data: singleData,
                    isNanos: fieldInfo.isNanos,
                    isSeconds: fieldInfo.isSeconds
                  )
                  return (nextIdx, ts)
                }
                return (nextIdx, nil)
              }
            }
          }
        }
      }
    }
    
    let sorted = sortIndicesByActivity(indices: validIndices, timestamps: allTimestamps)
    let errorMessage = allTimestamps.isEmpty ? "No document activity found in indices" : nil
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
