// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

public enum ClusterHealthStatus: String {
  case green, yellow, red, unknown

  public var title: String {
    rawValue.capitalized
  }

  public var explanation: String {
    switch self {
    case .green:
      return "All primary and replica shards are assigned"
    case .yellow:
      return "All primary shards are assigned, but one or more replicas are not"
    case .red:
      return "One or more primary shards are unassigned, so some data is unavailable"
    case .unknown:
      return "The cluster didn't report a status"
    }
  }
}

/// GET /_cluster/health
public struct ClusterHealthSummary: Equatable {
  public var clusterName: String = ""
  public var status: ClusterHealthStatus = .unknown
  public var timedOut: Bool = false
  public var numberOfNodes: Int = 0
  public var numberOfDataNodes: Int = 0
  public var activePrimaryShards: Int = 0
  public var activeShards: Int = 0
  public var relocatingShards: Int = 0
  public var initializingShards: Int = 0
  public var unassignedShards: Int = 0
  public var delayedUnassignedShards: Int = 0
  public var pendingTasks: Int = 0
  public var inFlightFetches: Int = 0
  public var taskMaxWaitingMillis: Int = 0
  public var activeShardsPercent: Double = 0

  /// Shards that aren't started, so their details are worth fetching
  public var hasShardIssues: Bool {
    relocatingShards + initializingShards + unassignedShards > 0
  }
}

/// GET /, the distribution and version
public struct ClusterInfo: Equatable {
  public var distribution: String
  public var version: String?

  public var label: String {
    [distribution, version].compactMap { $0 }.joined(separator: " ")
  }
}

/// GET /_cluster/stats
public struct ClusterStatsSummary: Equatable {
  public var indexCount: Int?
  public var documentCount: Int?
  public var storeSizeBytes: Int64?
  public var fsTotalBytes: Int64?
  public var fsAvailableBytes: Int64?
  public var heapUsedBytes: Int64?
  public var heapMaxBytes: Int64?
  public var versions: [String] = []

  public var fsUsedPercent: Double? {
    guard let total = fsTotalBytes, let available = fsAvailableBytes, total > 0 else { return nil }
    return Double(total - available) / Double(total) * 100
  }

  public var heapUsedPercent: Double? {
    guard let used = heapUsedBytes, let max = heapMaxBytes, max > 0 else { return nil }
    return Double(used) / Double(max) * 100
  }
}

/// A row from GET /_cat/nodes
public struct ClusterNode: Identifiable, Equatable {
  public var id: String { name + "|" + (ip ?? "") }
  public var name: String
  public var ip: String?
  public var roles: String?
  public var isElectedMaster: Bool
  public var version: String?
  public var heapPercent: Double?
  public var ramPercent: Double?
  public var cpuPercent: Double?
  public var load1m: Double?
  public var diskUsedPercent: Double?

  /// Spells out the role letters, eg. "dim" is data, ingest, master-eligible
  public var roleNames: [String] {
    guard let roles = roles, roles != "-" else { return ["coordinating only"] }
    let names: [Character: String] = [
      "c": "data cold", "d": "data", "f": "data frozen", "h": "data hot", "i": "ingest",
      "l": "machine learning", "m": "master-eligible", "r": "remote cluster client", "s": "data content",
      "t": "transform", "v": "voting only", "w": "data warm",
    ]
    return roles.map { names[$0] ?? String($0) }
  }
}

/// A shard that isn't started, from GET /_cat/shards
public struct ClusterShardIssue: Identifiable, Equatable {
  public var id: String { "\(index)|\(shard)|\(isPrimary)|\(node ?? "")|\(ordinal)" }
  public var index: String
  public var shard: String
  public var isPrimary: Bool
  public var state: String
  public var node: String?
  public var unassignedReason: String?
  // Several unassigned replicas of one shard share every other field
  var ordinal: Int = 0
}

public struct ClusterHealthResult {
  public var health: ClusterHealthSummary? = nil
  public var info: ClusterInfo? = nil
  public var stats: ClusterStatsSummary? = nil
  public var nodes: [ClusterNode] = []
  public var shardIssues: [ClusterShardIssue] = []
  // The extra sections are optional, the health request alone decides whether the page loads
  public var statsError: String? = nil
  public var nodesError: String? = nil
  public var shardsError: String? = nil
  public var error: ResponseError? = nil
}

@available(macOS 13.0, *)
@available(iOS 16.0.0, *)
public class ClusterHealth {

  static let healthEndpoint = "/_cluster/health"
  static let statsEndpoint = "/_cluster/stats"
  // Unknown columns are ignored, so asking for both names of the elected master column works
  // on Elasticsearch ("master") and OpenSearch ("cluster_manager")
  static let nodesEndpoint = "/_cat/nodes?format=json&h=name,ip,node.role,master,cluster_manager,version,heap.percent,ram.percent,cpu,load_1m,disk.used_percent"
  static let shardsEndpoint = "/_cat/shards?format=json&h=index,shard,prirep,state,node,unassigned.reason"

  /// Fetches the cluster's health, read only. The health request must succeed; stats, nodes
  /// and shard details are fetched alongside it and reported separately when they fail.
  @MainActor
  public static func fetch(serverDetails: HostDetails) async -> ClusterHealthResult {
    async let healthResponse = request(serverDetails: serverDetails, endpoint: healthEndpoint)
    async let infoResponse = request(serverDetails: serverDetails, endpoint: "")
    async let statsResponse = request(serverDetails: serverDetails, endpoint: statsEndpoint)
    async let nodesResponse = request(serverDetails: serverDetails, endpoint: nodesEndpoint)

    var result = ClusterHealthResult()

    let health = await healthResponse
    if let error = health.error {
      result.error = error
      return result
    }
    guard let summary = parseHealth(health.body) else {
      result.error = ResponseError(title: "Response Error",
                                   message: ClusterUsers.errorReason(health.body) ?? "Invalid JSON response received from host",
                                   type: .critical)
      return result
    }
    result.health = summary

    // Only worth listing shards when some aren't started, the full list can be large
    async let shardsResponse: RawResponse? = summary.hasShardIssues
      ? request(serverDetails: serverDetails, endpoint: shardsEndpoint)
      : nil

    let info = await infoResponse
    if info.error == nil {
      result.info = parseInfo(info.body)
    }

    let stats = await statsResponse
    if let error = stats.error {
      result.statsError = error.message
    } else if let parsed = parseStats(stats.body) {
      result.stats = parsed
    } else {
      result.statsError = "Invalid JSON response received from host"
    }

    let nodes = await nodesResponse
    if let error = nodes.error {
      result.nodesError = error.message
    } else if let parsed = parseNodes(nodes.body) {
      result.nodes = parsed
    } else {
      result.nodesError = "Invalid JSON response received from host"
    }

    if let shards = await shardsResponse {
      if let error = shards.error {
        result.shardsError = error.message
      } else if let parsed = parseShardIssues(shards.body) {
        result.shardIssues = parsed
      } else {
        result.shardsError = "Invalid JSON response received from host"
      }
    }

    return result
  }

  struct RawResponse {
    var body: String = ""
    var error: ResponseError? = nil
  }

  @MainActor
  private static func request(serverDetails: HostDetails, endpoint: String) async -> RawResponse {
    let clock = ContinuousClock()
    var response = ServerResponse()

    let timeTaken = await clock.measure {
      response = await Request().invoke(serverDetails: serverDetails, endpoint: endpoint)
      if let data = response.data {
        response.parsed = String(bytes: data, encoding: .utf8) ?? ""
      }
    }
    response.duration = timeTaken

    Logger.event(response: response, host: serverDetails)

    var result = RawResponse()
    if let error = response.error {
      result.error = error
      return result
    }

    result.body = response.parsed?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    if response.httpStatus >= 400 {
      let message = ClusterUsers.errorReason(result.body)
        ?? (result.body.isEmpty ? "Request failed with HTTP status \(response.httpStatus)" : result.body)
      result.error = ResponseError(title: "HTTP Error \(response.httpStatus)", message: message, type: .critical)
    }
    return result
  }

  // MARK: Parsing

  private static func object(_ body: String) -> JSON? {
    guard let data = body.data(using: .utf8),
          let json = try? JSON(data: data),
          json.type == .dictionary,
          json["error"] == JSON.null else {
      return nil
    }
    return json
  }

  public static func parseHealth(_ body: String) -> ClusterHealthSummary? {
    guard let json = object(body), json["status"].exists() else { return nil }

    var summary = ClusterHealthSummary()
    summary.clusterName = json["cluster_name"].stringValue
    summary.status = ClusterHealthStatus(rawValue: json["status"].stringValue.lowercased()) ?? .unknown
    summary.timedOut = json["timed_out"].boolValue
    summary.numberOfNodes = json["number_of_nodes"].intValue
    summary.numberOfDataNodes = json["number_of_data_nodes"].intValue
    summary.activePrimaryShards = json["active_primary_shards"].intValue
    summary.activeShards = json["active_shards"].intValue
    summary.relocatingShards = json["relocating_shards"].intValue
    summary.initializingShards = json["initializing_shards"].intValue
    summary.unassignedShards = json["unassigned_shards"].intValue
    summary.delayedUnassignedShards = json["delayed_unassigned_shards"].intValue
    summary.pendingTasks = json["number_of_pending_tasks"].intValue
    summary.inFlightFetches = json["number_of_in_flight_fetch"].intValue
    summary.taskMaxWaitingMillis = json["task_max_waiting_in_queue_millis"].intValue
    summary.activeShardsPercent = json["active_shards_percent_as_number"].doubleValue
    return summary
  }

  public static func parseInfo(_ body: String) -> ClusterInfo? {
    guard let json = object(body), json["version"].exists() else { return nil }
    let isOpenSearch = json["version"]["distribution"].string?.lowercased() == "opensearch"
    return ClusterInfo(distribution: isOpenSearch ? "OpenSearch" : "Elasticsearch",
                       version: json["version"]["number"].string)
  }

  public static func parseStats(_ body: String) -> ClusterStatsSummary? {
    guard let json = object(body), json["indices"].exists() || json["nodes"].exists() else { return nil }

    let indices = json["indices"]
    let nodes = json["nodes"]
    return ClusterStatsSummary(
      indexCount: indices["count"].int,
      documentCount: indices["docs"]["count"].int,
      storeSizeBytes: indices["store"]["size_in_bytes"].int64,
      fsTotalBytes: nodes["fs"]["total_in_bytes"].int64,
      fsAvailableBytes: nodes["fs"]["available_in_bytes"].int64,
      heapUsedBytes: nodes["jvm"]["mem"]["heap_used_in_bytes"].int64,
      heapMaxBytes: nodes["jvm"]["mem"]["heap_max_in_bytes"].int64,
      versions: nodes["versions"].arrayValue.compactMap { $0.string }
    )
  }

  /// Nodes sorted by name, or nil when the body isn't a JSON array
  public static func parseNodes(_ body: String) -> [ClusterNode]? {
    guard let data = body.data(using: .utf8),
          let json = try? JSON(data: data),
          let rows = json.array else {
      return nil
    }

    return rows.map { row in
      let master = row["master"].string ?? row["cluster_manager"].string
      return ClusterNode(
        name: row["name"].string ?? "Unnamed node",
        ip: row["ip"].string,
        roles: row["node.role"].string,
        isElectedMaster: master == "*",
        version: row["version"].string,
        heapPercent: number(row["heap.percent"]),
        ramPercent: number(row["ram.percent"]),
        cpuPercent: number(row["cpu"]),
        load1m: number(row["load_1m"]),
        diskUsedPercent: number(row["disk.used_percent"])
      )
    }
    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
  }

  /// Shards that aren't STARTED, unassigned primaries first, or nil when the body isn't a JSON array
  public static func parseShardIssues(_ body: String) -> [ClusterShardIssue]? {
    guard let data = body.data(using: .utf8),
          let json = try? JSON(data: data),
          let rows = json.array else {
      return nil
    }

    var seen: [String: Int] = [:]
    let issues: [ClusterShardIssue] = rows.compactMap { row in
      let state = row["state"].stringValue.uppercased()
      guard !state.isEmpty, state != "STARTED" else { return nil }
      var issue = ClusterShardIssue(
        index: row["index"].stringValue,
        shard: row["shard"].stringValue,
        isPrimary: row["prirep"].stringValue == "p",
        state: state,
        node: row["node"].string,
        unassignedReason: row["unassigned.reason"].string
      )
      let key = issue.id
      issue.ordinal = seen[key, default: 0]
      seen[key] = issue.ordinal + 1
      return issue
    }

    return issues.sorted { lhs, rhs in
      if severity(lhs) != severity(rhs) { return severity(lhs) < severity(rhs) }
      if lhs.index != rhs.index { return lhs.index.localizedStandardCompare(rhs.index) == .orderedAscending }
      return (Int(lhs.shard) ?? 0) < (Int(rhs.shard) ?? 0)
    }
  }

  private static func severity(_ issue: ClusterShardIssue) -> Int {
    switch (issue.state, issue.isPrimary) {
    case ("UNASSIGNED", true): return 0
    case ("UNASSIGNED", false): return 1
    case ("INITIALIZING", _): return 2
    default: return 3
    }
  }

  /// _cat values are strings, eg. "12" or "0.54", or null when the node can't report them
  private static func number(_ value: JSON) -> Double? {
    if let double = value.double { return double }
    guard let string = value.string?.trimmingCharacters(in: .whitespaces) else { return nil }
    return Double(string)
  }
}
