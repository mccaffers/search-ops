// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public struct DeleteByQueryResult: Equatable, Sendable {
  public var took: Int?
  public var timedOut: Bool?
  public var total: Int?
  public var deleted: Int?
  public var batches: Int?
  public var versionConflicts: Int?
  public var noops: Int?
  public var failures: [String]
  public var errorMessage: String?
  public var isSuccess: Bool

  public init(
    took: Int? = nil,
    timedOut: Bool? = nil,
    total: Int? = nil,
    deleted: Int? = nil,
    batches: Int? = nil,
    versionConflicts: Int? = nil,
    noops: Int? = nil,
    failures: [String] = [],
    errorMessage: String? = nil,
    isSuccess: Bool = true
  ) {
    self.took = took
    self.timedOut = timedOut
    self.total = total
    self.deleted = deleted
    self.batches = batches
    self.versionConflicts = versionConflicts
    self.noops = noops
    self.failures = failures
    self.errorMessage = errorMessage
    self.isSuccess = isSuccess
  }
}

public struct IndexAgeHelper {
  public static func dateMathUnit(for period: SearchDateTimePeriods) -> String {
    switch period {
    case .Seconds:
      return "s"
    case .Minutes:
      return "m"
    case .Hours:
      return "h"
    case .Days:
      return "d"
    case .Weeks:
      return "w"
    case .Months:
      return "M"
    case .Years:
      return "y"
    }
  }

  public static func dateMathExpression(value: Int, period: SearchDateTimePeriods) -> String {
    let safeValue = max(1, value)
    let unit = dateMathUnit(for: period)
    return "now-\(safeValue)\(unit)"
  }

  public static func calculateCutoffDate(from referenceDate: Date = Date(), value: Int, period: SearchDateTimePeriods) -> Date {
    let calendar = Calendar.current
    let safeValue = max(1, value)
    switch period {
    case .Seconds:
      return calendar.date(byAdding: .second, value: -safeValue, to: referenceDate) ?? referenceDate
    case .Minutes:
      return calendar.date(byAdding: .minute, value: -safeValue, to: referenceDate) ?? referenceDate
    case .Hours:
      return calendar.date(byAdding: .hour, value: -safeValue, to: referenceDate) ?? referenceDate
    case .Days:
      return calendar.date(byAdding: .day, value: -safeValue, to: referenceDate) ?? referenceDate
    case .Weeks:
      return calendar.date(byAdding: .day, value: -(safeValue * 7), to: referenceDate) ?? referenceDate
    case .Months:
      return calendar.date(byAdding: .month, value: -safeValue, to: referenceDate) ?? referenceDate
    case .Years:
      return calendar.date(byAdding: .year, value: -safeValue, to: referenceDate) ?? referenceDate
    }
  }

  public static func formatCutoffDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  public static func buildRangeDeleteQuery(dateField: String, dateMathExpression: String) -> String {
    let queryDict: [String: Any] = [
      "query": [
        "range": [
          dateField: [
            "lt": dateMathExpression
          ]
        ]
      ]
    ]
    if let data = try? JSONSerialization.data(withJSONObject: queryDict, options: []),
       let str = String(data: data, encoding: .utf8) {
      return str
    }
    return "{\"query\":{\"range\":{\"\(dateField)\":{\"lt\":\"\(dateMathExpression)\"}}}}"
  }

  public static func buildMatchAllDeleteQuery() -> String {
    return "{\"query\":{\"match_all\":{}}}"
  }
}

@MainActor
public class IndexManagementService {

  public static func fetchIndexMapping(
    serverDetails: HostDetails,
    index: String
  ) async -> (fields: [SquashedFieldsArray], dateFields: [DateFieldInfo], rawJson: String, error: ResponseError?) {
    let endpoint = "/\(index)/_mapping"
    var response = await Request().invoke(serverDetails: serverDetails, endpoint: endpoint)

    if let data = response.data {
      response.parsed = String(bytes: data, encoding: .utf8) ?? ""
    }

    Logger.event(response: response, index: index, host: serverDetails)

    if response.httpStatus >= 400 {
      let err = parseErrorMessage(from: response.data, httpStatus: response.httpStatus, defaultTitle: "Mapping Error")
      return (fields: [], dateFields: [], rawJson: response.parsed ?? "", error: err ?? response.error)
    }

    if let err = response.error {
      return (fields: [], dateFields: [], rawJson: response.parsed ?? "", error: err)
    }

    let rawJson = response.parsed ?? ""
    guard let data = response.data else {
      return (fields: [], dateFields: [], rawJson: "", error: ResponseError(title: "Mapping Error", message: "No data received", type: .warn))
    }

    let fields = await IndexMap.indexMappingsResponseToArray(rawJson)
    let dateFieldsByIndices = IndexActivityService.parseDateFieldsByIndices(from: data, targetIndices: [])

    var allDateFields: [DateFieldInfo] = []
    var seenDateFields = Set<DateFieldInfo>()
    for (_, dateFields) in dateFieldsByIndices {
      for df in dateFields {
        if seenDateFields.insert(df).inserted {
          allDateFields.append(df)
        }
      }
    }

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

    allDateFields.sort { a, b in
      let rankA = rank(for: a.name)
      let rankB = rank(for: b.name)
      if rankA != rankB { return rankA < rankB }
      let dotsA = a.name.filter { $0 == "." }.count
      let dotsB = b.name.filter { $0 == "." }.count
      if dotsA != dotsB { return dotsA < dotsB }
      if a.name.count != b.name.count { return a.name.count < b.name.count }
      let comp = a.name.localizedStandardCompare(b.name)
      if comp != .orderedSame { return comp == .orderedAscending }
      if a.isNanos != b.isNanos { return a.isNanos && !b.isNanos }
      return a.isSeconds && !b.isSeconds
    }

    var seenNames = Set<String>()
    var deduplicatedDateFields: [DateFieldInfo] = []
    for df in allDateFields {
      if seenNames.insert(df.name).inserted {
        deduplicatedDateFields.append(df)
      }
    }

    return (fields: fields, dateFields: deduplicatedDateFields, rawJson: rawJson, error: nil)
  }

  public static func deleteAllDocuments(
    serverDetails: HostDetails,
    index: String
  ) async -> DeleteByQueryResult {
    let endpoint = "/\(index)/_delete_by_query?conflicts=proceed&refresh=true&timeout=60s"
    let query = IndexAgeHelper.buildMatchAllDeleteQuery()

    let response = await Request().invoke(
      serverDetails: serverDetails,
      endpoint: endpoint,
      json: query,
      timeoutInterval: 120.0
    )

    if let data = response.data {
      response.parsed = String(bytes: data, encoding: .utf8) ?? ""
    }

    Logger.event(response: response, index: index, host: serverDetails)

    return parseDeleteResponse(response.data, httpStatus: response.httpStatus, requestError: response.error)
  }

  public static func deleteDocumentsByAge(
    serverDetails: HostDetails,
    index: String,
    dateField: String,
    dateMathExpression: String
  ) async -> DeleteByQueryResult {
    let endpoint = "/\(index)/_delete_by_query?conflicts=proceed&refresh=true&timeout=60s"
    let query = IndexAgeHelper.buildRangeDeleteQuery(dateField: dateField, dateMathExpression: dateMathExpression)

    let response = await Request().invoke(
      serverDetails: serverDetails,
      endpoint: endpoint,
      json: query,
      timeoutInterval: 120.0
    )

    if let data = response.data {
      response.parsed = String(bytes: data, encoding: .utf8) ?? ""
    }

    Logger.event(response: response, index: index, host: serverDetails)

    return parseDeleteResponse(response.data, httpStatus: response.httpStatus, requestError: response.error)
  }

  public nonisolated static func extractIndexStats(
    from parsedStats: [String: IndexStatsItem],
    for indexName: String
  ) -> IndexStatsItem? {
    if let item = parsedStats[indexName] {
      return item
    }
    guard !parsedStats.isEmpty else { return nil }
    if parsedStats.count == 1, let single = parsedStats.values.first {
      return single
    }
    let totalDocCount = parsedStats.values.reduce(0) { $0 + ($1.docCount ?? 0) }
    let totalStorageBytes = parsedStats.values.reduce(Int64(0)) { $0 + ($1.storageBytes ?? 0) }
    let totalTotalDocCount = parsedStats.values.reduce(0) { $0 + ($1.totalDocCount ?? 0) }
    let totalTotalStorageBytes = parsedStats.values.reduce(Int64(0)) { $0 + ($1.totalStorageBytes ?? 0) }
    let totalDeletedDocs = parsedStats.values.reduce(0) { $0 + ($1.deletedDocCount ?? 0) }

    return IndexStatsItem(
      docCount: totalDocCount,
      storageBytes: totalStorageBytes,
      totalDocCount: totalTotalDocCount,
      totalStorageBytes: totalTotalStorageBytes,
      deletedDocCount: totalDeletedDocs
    )
  }

  public nonisolated static func parseDeleteResponse(
    _ data: Data?,
    httpStatus: Int? = nil,
    requestError: ResponseError? = nil
  ) -> DeleteByQueryResult {
    if let requestError = requestError {
      return DeleteByQueryResult(
        failures: [],
        errorMessage: requestError.message,
        isSuccess: false
      )
    }

    if let errorErr = parseErrorMessage(from: data, httpStatus: httpStatus) {
      return DeleteByQueryResult(
        failures: [],
        errorMessage: errorErr.message,
        isSuccess: false
      )
    }

    guard let data = data, !data.isEmpty else {
      let msg = httpStatus.map { "HTTP \($0): No data received from cluster" } ?? "No data received from cluster"
      return DeleteByQueryResult(
        failures: [],
        errorMessage: msg,
        isSuccess: false
      )
    }

    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
      let rawStr = String(data: data, encoding: .utf8) ?? "Invalid response format"
      return DeleteByQueryResult(
        failures: [],
        errorMessage: rawStr,
        isSuccess: false
      )
    }

    let took = json["took"] as? Int
    let timedOut = json["timed_out"] as? Bool
    let total = json["total"] as? Int
    let deleted = json["deleted"] as? Int
    let batches = json["batches"] as? Int
    let versionConflicts = json["version_conflicts"] as? Int
    let noops = json["noops"] as? Int

    var failureStrings: [String] = []
    if let rawFailures = json["failures"] as? [Any] {
      for item in rawFailures {
        if let failureDict = item as? [String: Any] {
          if let cause = failureDict["cause"] as? [String: Any],
             let reason = cause["reason"] as? String {
            failureStrings.append(reason)
          } else if let reason = failureDict["reason"] as? String {
            failureStrings.append(reason)
          } else {
            failureStrings.append("\(failureDict)")
          }
        } else if let failureStr = item as? String {
          failureStrings.append(failureStr)
        }
      }
    }

    let isSuccess = failureStrings.isEmpty && !(timedOut ?? false)
    let errorMessage = failureStrings.first ?? (timedOut == true ? "Operation timed out on cluster" : nil)

    return DeleteByQueryResult(
      took: took,
      timedOut: timedOut,
      total: total,
      deleted: deleted,
      batches: batches,
      versionConflicts: versionConflicts,
      noops: noops,
      failures: failureStrings,
      errorMessage: errorMessage,
      isSuccess: isSuccess
    )
  }

  public nonisolated static func parseErrorMessage(
    from data: Data?,
    httpStatus: Int? = nil,
    defaultTitle: String = "Operation Failed"
  ) -> ResponseError? {
    let statusTitle = httpStatus.map { "HTTP Error \($0)" } ?? defaultTitle

    guard let data = data, !data.isEmpty else {
      if let status = httpStatus, status >= 400 {
        return ResponseError(title: statusTitle, message: "Request failed with HTTP status \(status)", type: .critical)
      }
      return nil
    }

    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
      if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
        if str.hasPrefix("<") || str.localizedCaseInsensitiveContains("<html") {
          let msg = httpStatus.map { "Server returned HTTP \($0)" } ?? "Server returned an HTML error response"
          return ResponseError(title: statusTitle, message: msg, type: .critical)
        }
        let cleanMsg = str.count > 300 ? String(str.prefix(300)) + "..." : str
        return ResponseError(title: statusTitle, message: cleanMsg, type: .warn)
      }
      if let status = httpStatus, status >= 400 {
        return ResponseError(title: statusTitle, message: "Request failed with HTTP status \(status)", type: .critical)
      }
      return nil
    }

    if let errorObj = json["error"] as? [String: Any] {
      if let rootCauses = errorObj["root_cause"] as? [[String: Any]],
         let firstCause = rootCauses.first,
         let reason = firstCause["reason"] as? String, !reason.isEmpty {
        let type = firstCause["type"] as? String ?? statusTitle
        return ResponseError(title: type, message: reason, type: .warn)
      }

      if let reason = errorObj["reason"] as? String, !reason.isEmpty {
        let type = errorObj["type"] as? String ?? statusTitle
        return ResponseError(title: type, message: reason, type: .warn)
      }
    }

    if let errorStr = json["error"] as? String, !errorStr.isEmpty {
      return ResponseError(title: statusTitle, message: errorStr, type: .warn)
    }

    if let message = json["message"] as? String, !message.isEmpty {
      return ResponseError(title: statusTitle, message: message, type: .warn)
    }

    if let status = httpStatus, status >= 400 {
      return ResponseError(title: statusTitle, message: "Request failed with HTTP status \(status)", type: .critical)
    }

    return nil
  }
}
