// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import Testing

@testable import Search_Ops

struct ClusterHealthTests {

  // MARK: GET /_cluster/health

  @Test func parseHealth() throws {
    let body = """
    {
      "cluster_name": "trading", "status": "yellow", "timed_out": false,
      "number_of_nodes": 3, "number_of_data_nodes": 2,
      "active_primary_shards": 40, "active_shards": 75, "relocating_shards": 1,
      "initializing_shards": 2, "unassigned_shards": 5, "delayed_unassigned_shards": 1,
      "number_of_pending_tasks": 4, "number_of_in_flight_fetch": 0,
      "task_max_waiting_in_queue_millis": 1500, "active_shards_percent_as_number": 90.36144578313254
    }
    """

    let health = try #require(ClusterHealth.parseHealth(body))

    #expect(health.clusterName == "trading")
    #expect(health.status == .yellow)
    #expect(health.timedOut == false)
    #expect(health.numberOfNodes == 3)
    #expect(health.numberOfDataNodes == 2)
    #expect(health.activePrimaryShards == 40)
    #expect(health.activeShards == 75)
    #expect(health.relocatingShards == 1)
    #expect(health.initializingShards == 2)
    #expect(health.unassignedShards == 5)
    #expect(health.delayedUnassignedShards == 1)
    #expect(health.pendingTasks == 4)
    #expect(health.taskMaxWaitingMillis == 1500)
    #expect(abs(health.activeShardsPercent - 90.36) < 0.01)
    #expect(health.hasShardIssues)
  }

  @Test func parseGreenHealthHasNoShardIssues() throws {
    let body = """
    { "cluster_name": "c", "status": "GREEN", "active_shards": 10, "relocating_shards": 0,
      "initializing_shards": 0, "unassigned_shards": 0, "active_shards_percent_as_number": 100.0 }
    """

    let health = try #require(ClusterHealth.parseHealth(body))

    #expect(health.status == .green)
    #expect(health.hasShardIssues == false)
  }

  @Test func parseHealthRejectsErrorsAndOtherBodies() {
    let error = """
    { "error": { "root_cause": [{ "type": "security_exception", "reason": "action [cluster:monitor/health] is unauthorized" }] }, "status": 403 }
    """
    #expect(ClusterHealth.parseHealth(error) == nil)
    #expect(ClusterHealth.parseHealth("[]") == nil)
    #expect(ClusterHealth.parseHealth("{}") == nil)
    #expect(ClusterHealth.parseHealth("not json") == nil)
  }

  @Test func unknownStatus() throws {
    let health = try #require(ClusterHealth.parseHealth(#"{ "status": "purple" }"#))
    #expect(health.status == .unknown)
  }

  // MARK: GET /

  @Test func parseElasticsearchInfo() throws {
    let body = """
    { "name": "node-1", "cluster_name": "trading",
      "version": { "number": "8.15.1", "build_flavor": "default" }, "tagline": "You Know, for Search" }
    """

    let info = try #require(ClusterHealth.parseInfo(body))

    #expect(info.distribution == "Elasticsearch")
    #expect(info.version == "8.15.1")
    #expect(info.label == "Elasticsearch 8.15.1")
  }

  @Test func parseOpenSearchInfo() throws {
    let body = """
    { "name": "os-1", "version": { "distribution": "opensearch", "number": "2.17.0" }, "tagline": "The OpenSearch Project" }
    """

    let info = try #require(ClusterHealth.parseInfo(body))

    #expect(info.label == "OpenSearch 2.17.0")
  }

  // MARK: GET /_cluster/stats

  @Test func parseStats() throws {
    let body = """
    {
      "cluster_name": "trading", "status": "green",
      "indices": { "count": 12, "docs": { "count": 123456 }, "store": { "size_in_bytes": 1073741824 } },
      "nodes": {
        "count": { "total": 3 }, "versions": ["8.15.1"],
        "jvm": { "mem": { "heap_used_in_bytes": 512, "heap_max_in_bytes": 2048 } },
        "fs": { "total_in_bytes": 1000, "free_in_bytes": 300, "available_in_bytes": 250 }
      }
    }
    """

    let stats = try #require(ClusterHealth.parseStats(body))

    #expect(stats.indexCount == 12)
    #expect(stats.documentCount == 123456)
    #expect(stats.storeSizeBytes == 1073741824)
    #expect(stats.versions == ["8.15.1"])
    #expect(stats.heapUsedPercent == 25)
    #expect(stats.fsUsedPercent == 75, "Used is total minus what's available to the node, not free")
  }

  @Test func statsPercentagesNeedTotals() throws {
    let stats = try #require(ClusterHealth.parseStats(#"{ "indices": { "count": 0 }, "nodes": { "fs": { "total_in_bytes": 0, "available_in_bytes": 0 } } }"#))
    #expect(stats.fsUsedPercent == nil)
    #expect(stats.heapUsedPercent == nil)
  }

  // MARK: GET /_cat/nodes

  @Test func parseElasticsearchNodes() throws {
    let body = """
    [
      { "name": "node-b", "ip": "10.0.0.2", "node.role": "dim", "master": "*", "version": "8.15.1",
        "heap.percent": "41", "ram.percent": "97", "cpu": "3", "load_1m": "0.54", "disk.used_percent": "71.20" },
      { "name": "node-a", "ip": "10.0.0.1", "node.role": "-", "master": "-", "version": "8.15.1",
        "heap.percent": "12", "ram.percent": "80", "cpu": "1", "load_1m": null, "disk.used_percent": null }
    ]
    """

    let nodes = try #require(ClusterHealth.parseNodes(body))

    #expect(nodes.map(\.name) == ["node-a", "node-b"])

    let coordinating = nodes[0]
    #expect(coordinating.isElectedMaster == false)
    #expect(coordinating.load1m == nil)
    #expect(coordinating.diskUsedPercent == nil)
    #expect(coordinating.roleNames == ["coordinating only"])

    let master = nodes[1]
    #expect(master.isElectedMaster)
    #expect(master.heapPercent == 41)
    #expect(master.ramPercent == 97)
    #expect(master.cpuPercent == 3)
    #expect(master.load1m == 0.54)
    #expect(master.diskUsedPercent == 71.2)
    #expect(master.roleNames == ["data", "ingest", "master-eligible"])
  }

  @Test func parseOpenSearchNodesUsesClusterManagerColumn() throws {
    let body = """
    [ { "name": "os-1", "ip": "10.0.0.9", "node.role": "dimr", "cluster_manager": "*", "heap.percent": "20" } ]
    """

    let nodes = try #require(ClusterHealth.parseNodes(body))

    #expect(nodes.first?.isElectedMaster == true)
  }

  @Test func parseNodesRejectsErrors() {
    #expect(ClusterHealth.parseNodes(#"{ "error": "nope" }"#) == nil)
  }

  // MARK: GET /_cat/shards

  @Test func parseShardIssuesKeepsOnlyUnstartedShards() throws {
    let body = """
    [
      { "index": "logs", "shard": "0", "prirep": "p", "state": "STARTED", "node": "node-a", "unassigned.reason": null },
      { "index": "logs", "shard": "1", "prirep": "r", "state": "INITIALIZING", "node": "node-b", "unassigned.reason": "REPLICA_ADDED" },
      { "index": "orders", "shard": "10", "prirep": "r", "state": "UNASSIGNED", "node": null, "unassigned.reason": "NODE_LEFT" },
      { "index": "orders", "shard": "10", "prirep": "r", "state": "UNASSIGNED", "node": null, "unassigned.reason": "NODE_LEFT" },
      { "index": "orders", "shard": "2", "prirep": "r", "state": "UNASSIGNED", "node": null, "unassigned.reason": "NODE_LEFT" },
      { "index": "trades", "shard": "0", "prirep": "p", "state": "UNASSIGNED", "node": null, "unassigned.reason": "ALLOCATION_FAILED" },
      { "index": "audit", "shard": "0", "prirep": "p", "state": "RELOCATING", "node": "node-a -> 10.0.0.2 node-b" }
    ]
    """

    let issues = try #require(ClusterHealth.parseShardIssues(body))

    #expect(issues.count == 6)
    // Unassigned primaries, unassigned replicas, initialising, then the rest
    #expect(issues.map(\.index) == ["trades", "orders", "orders", "orders", "logs", "audit"])
    #expect(issues.map(\.shard) == ["0", "2", "10", "10", "1", "0"])
    #expect(issues[0].isPrimary)
    #expect(issues[0].unassignedReason == "ALLOCATION_FAILED")
    #expect(issues[1].node == nil)
    #expect(Set(issues.map(\.id)).count == issues.count, "Identical unassigned replicas still get their own id")
  }

  @Test func parseShardIssuesWhenAllStarted() throws {
    let issues = try #require(ClusterHealth.parseShardIssues(#"[ { "index": "a", "shard": "0", "prirep": "p", "state": "STARTED" } ]"#))
    #expect(issues.isEmpty)
  }
}
