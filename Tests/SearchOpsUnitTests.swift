// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import Testing

@testable import Search_Ops

struct SearchOpsUnitTests {
  
  @Test func testEquality() {
    let field1 = FieldsArray(name: "FieldA")
    let field2 = FieldsArray(name: "FieldA")
    XCTAssertEqual(field1, field2, "FieldsArray instances with the same name should be equal")
  }

  @Test func testIndexFilter_emptyAndWhitespaceQuery() {
    let indices = ["logs-2025", "audit", "metrics"]
    XCTAssertEqual(IndexFilterHelper.filter(indices: indices, query: ""), ["audit", "logs-2025", "metrics"])
    XCTAssertEqual(IndexFilterHelper.filter(indices: indices, query: "   \n"), ["audit", "logs-2025", "metrics"])
  }

  @Test func testIndexFilter_caseInsensitiveSubstring() {
    let indices = ["audit-log", "APP-LOGS", "metrics-2025", "system"]
    let filtered = IndexFilterHelper.filter(indices: indices, query: "log")
    XCTAssertEqual(filtered, ["APP-LOGS", "audit-log"])
  }

  @Test func testIndexFilter_wildcardAsterisk() {
    let indices = ["logs-2025-01", "logs-2024-12", "metrics-logs", "audit"]
    let filteredPrefix = IndexFilterHelper.filter(indices: indices, query: "logs-*")
    XCTAssertEqual(filteredPrefix, ["logs-2024-12", "logs-2025-01"])

    let filteredSuffix = IndexFilterHelper.filter(indices: indices, query: "*logs")
    XCTAssertEqual(filteredSuffix, ["metrics-logs"])
  }

  @Test func testIndexFilter_wildcardQuestionMark() {
    let indices = ["log1", "log2", "log10", "other"]
    let filtered = IndexFilterHelper.filter(indices: indices, query: "log?")
    XCTAssertEqual(filtered, ["log1", "log2"])
  }

  @Test func testIndexFilter_specialCharactersEscaped() {
    let indices = ["app.prod", "appXprod", "data(old)", "data_new"]
    let filteredDot = IndexFilterHelper.filter(indices: indices, query: "app.prod")
    XCTAssertEqual(filteredDot, ["app.prod"])

    let filteredParens = IndexFilterHelper.filter(indices: indices, query: "(old)")
    XCTAssertEqual(filteredParens, ["data(old)"])
  }

  @Test func testIndexFilter_deduplicationAndEmpty() {
    let duplicateIndices = ["audit", "audit", "metrics", "audit"]
    XCTAssertEqual(IndexFilterHelper.filter(indices: duplicateIndices, query: ""), ["audit", "metrics"])

    let emptyIndices: [String] = []
    XCTAssertEqual(IndexFilterHelper.filter(indices: emptyIndices, query: "logs"), [])
  }

  @Test func testIndexFilter_noMatches() {
    let indices = ["logs", "metrics", "traces"]
    XCTAssertEqual(IndexFilterHelper.filter(indices: indices, query: "k8s"), [])
  }

  @Test func testIndexFilter_showAllButton() {
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: ""))
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: "   "))
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: "all"))
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: "_all"))
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: "_ALL"))
    XCTAssertTrue(IndexFilterHelper.showAllButton(query: "*all*"))
    XCTAssertFalse(IndexFilterHelper.showAllButton(query: "logs"))
    XCTAssertFalse(IndexFilterHelper.showAllButton(query: "audit"))
  }

  @Test func testIndexFilter_excludesAllPseudoIndex() {
    let indicesWithAll = ["_all", "audit", "metrics"]
    let filtered = IndexFilterHelper.filter(indices: indicesWithAll, query: "")
    XCTAssertEqual(filtered, ["audit", "metrics"])
    XCTAssertFalse(filtered.contains("_all"))

    let filteredSearch = IndexFilterHelper.filter(indices: indicesWithAll, query: "all")
    XCTAssertEqual(filteredSearch, [])
  }

  @Test func testIndexFilter_totalCount() {
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: []), 1)
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: ["audit", "metrics"]), 3)
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: ["audit", "audit", "metrics"]), 3)
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: ["_all", "audit", "metrics"]), 3)
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: ["_all", "audit", "audit"]), 2)
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: [], includeAll: false), 0)
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: ["audit", "metrics"], includeAll: false), 2)
    XCTAssertEqual(IndexFilterHelper.totalCount(indices: ["_all", "audit", "metrics"], includeAll: false), 2)
  }

  @Test func testIndexFilter_consecutiveWildcards() {
    let indices = ["logs-2025-01", "logs-2024-12", "metrics"]
    let filteredDouble = IndexFilterHelper.filter(indices: indices, query: "logs**01")
    XCTAssertEqual(filteredDouble, ["logs-2025-01"])

    let filteredTriple = IndexFilterHelper.filter(indices: indices, query: "***metrics***")
    XCTAssertEqual(filteredTriple, ["metrics"])
  }

  @Test func testIndexFilter_complexPatterns() {
    let indices = ["k8s-prod.logs", "k8s-dev.logs", "k8s-prod.metrics", "other"]
    let filtered = IndexFilterHelper.filter(indices: indices, query: "k8s-*.logs")
    XCTAssertEqual(filtered, ["k8s-dev.logs", "k8s-prod.logs"])

    let singleChar = IndexFilterHelper.filter(indices: ["cat", "cot", "coat", "cut"], query: "c?t")
    XCTAssertEqual(singleChar, ["cat", "cot", "cut"])
  }

  @Test func testIndexFilter_preserveOrderDeduplication() {
    let customOrder = ["zebra-index", "alpha-index", "beta-index", "alpha-index", "_all"]
    let filteredDefault = IndexFilterHelper.filter(indices: customOrder, query: "")
    // Default alphabetical sorting
    XCTAssertEqual(filteredDefault, ["alpha-index", "beta-index", "zebra-index"])
    
    // preserveOrder: true keeps incoming order and deduplicates, excludes _all
    let filteredPreserved = IndexFilterHelper.filter(indices: customOrder, query: "", preserveOrder: true)
    XCTAssertEqual(filteredPreserved, ["zebra-index", "alpha-index", "beta-index"])
    
    // With query filter and preserveOrder
    let withQuery = IndexFilterHelper.filter(indices: customOrder, query: "a-index", preserveOrder: true)
    XCTAssertEqual(withQuery, ["zebra-index", "alpha-index", "beta-index"])
  }

  @Test func testIndexFilter_displayLimitingAndBoundary() {
    XCTAssertEqual(IndexFilterHelper.defaultDisplayLimit, 30)
    
    let empty: [String] = []
    XCTAssertEqual(IndexFilterHelper.limitIndices(empty), [])
    XCTAssertFalse(IndexFilterHelper.hasExceededLimit(empty))
    
    let fifteen = (1...15).map { "index-\($0)" }
    XCTAssertEqual(IndexFilterHelper.limitIndices(fifteen).count, 15)
    XCTAssertFalse(IndexFilterHelper.hasExceededLimit(fifteen))
    
    let thirty = (1...30).map { "index-\($0)" }
    XCTAssertEqual(IndexFilterHelper.limitIndices(thirty).count, 30)
    XCTAssertFalse(IndexFilterHelper.hasExceededLimit(thirty))
    
    let thirtyOne = (1...31).map { "index-\($0)" }
    XCTAssertEqual(IndexFilterHelper.limitIndices(thirtyOne).count, 30)
    XCTAssertEqual(IndexFilterHelper.limitIndices(thirtyOne), Array(thirtyOne.prefix(30)))
    XCTAssertTrue(IndexFilterHelper.hasExceededLimit(thirtyOne))
    
    let fifty = (1...50).map { "index-\($0)" }
    XCTAssertEqual(IndexFilterHelper.limitIndices(fifty).count, 30)
    XCTAssertTrue(IndexFilterHelper.hasExceededLimit(fifty))
  }

  @Test func testIndexActivityService_dateFieldExtraction() {
    let mockMappingJSON = """
    {
      "logs-v8": {
        "mappings": {
          "properties": {
            "@timestamp": { "type": "date" },
            "user": {
              "properties": {
                "created_at": { "type": "date_nanos" }
              }
            },
            "message": { "type": "text" }
          }
        }
      },
      "logs-v6": {
        "mappings": {
          "doc": {
            "properties": {
              "timestamp": { "type": "date" },
              "count": { "type": "integer" }
            }
          }
        }
      },
      "system-index": {
        "mappings": {
          "properties": {
            "@timestamp": { "type": "date" }
          }
        }
      }
    }
    """.data(using: .utf8)!
    
    let targetIndices: Set<String> = ["logs-v8", "logs-v6"]
    let parsed = IndexActivityService.parseDateFieldsByIndices(from: mockMappingJSON, targetIndices: targetIndices)
    
    // "system-index" was not in targetIndices, so should be ignored
    XCTAssertNil(parsed["system-index"])
    
    let v8Fields = parsed["logs-v8"] ?? []
    XCTAssertTrue(v8Fields.contains(DateFieldInfo(name: "@timestamp", isNanos: false)))
    XCTAssertTrue(v8Fields.contains(DateFieldInfo(name: "user.created_at", isNanos: true)))
    XCTAssertFalse(v8Fields.contains(DateFieldInfo(name: "message", isNanos: false)))
    
    let v6Fields = parsed["logs-v6"] ?? []
    XCTAssertTrue(v6Fields.contains(DateFieldInfo(name: "timestamp", isNanos: false)))
  }

  @Test func testIndexActivityService_datePriority() {
    let fields = [
      DateFieldInfo(name: "created_at", isNanos: false),
      DateFieldInfo(name: "@timestamp", isNanos: false),
      DateFieldInfo(name: "updated_at", isNanos: false)
    ]
    let best = IndexActivityService.selectBestDateField(from: fields)
    XCTAssertEqual(best?.name, "@timestamp")
    
    let fieldsWithoutAt = [
      DateFieldInfo(name: "created_at", isNanos: false),
      DateFieldInfo(name: "updated_at", isNanos: false),
      DateFieldInfo(name: "random_field", isNanos: false)
    ]
    let bestSecond = IndexActivityService.selectBestDateField(from: fieldsWithoutAt)
    XCTAssertEqual(bestSecond?.name, "updated_at")
  }

  @Test func testIndexActivityService_nanosNormalization() {
    // 1700000000000 ms = 1700000000000000000 ns
    let nanosJSON = """
    {
      "aggregations": {
        "max_date": {
          "value": 1700000000000000000
        }
      }
    }
    """.data(using: .utf8)!
    
    let normalized = IndexActivityService.parseSingleMaxTimestamp(data: nanosJSON, isNanos: true)
    XCTAssertEqual(normalized, 1700000000000.0)
    
    let standardDateJSON = """
    {
      "aggregations": {
        "max_date": {
          "value": 1700000000000.0
        }
      }
    }
    """.data(using: .utf8)!
    
    let standard = IndexActivityService.parseSingleMaxTimestamp(data: standardDateJSON, isNanos: false)
    XCTAssertEqual(standard, 1700000000000.0)
  }

  @Test func testIndexActivityService_batchedAggregationParsing() {
    let batchedJSON = """
    {
      "aggregations": {
        "by_index": {
          "buckets": [
            {
              "key": "idx-1",
              "doc_count": 50,
              "max_date": { "value": 1705000000000.0 }
            },
            {
              "key": "idx-2",
              "doc_count": 10,
              "max_date": { "value": 1704000000000.0 }
            },
            {
              "key": "idx-empty",
              "doc_count": 0,
              "max_date": { "value": null }
            }
          ]
        }
      }
    }
    """.data(using: .utf8)!
    
    let timestamps = IndexActivityService.parseBatchedAggResponse(data: batchedJSON, isNanos: false)
    XCTAssertEqual(timestamps["idx-1"], 1705000000000.0)
    XCTAssertEqual(timestamps["idx-2"], 1704000000000.0)
    XCTAssertNil(timestamps["idx-empty"])
  }

  @Test func testIndexActivityService_sortingTieBreakers() {
    let indices = ["dateless-b", "active-newer", "dateless-a", "active-older", "active-tie-b", "active-tie-a"]
    let timestamps: [String: Double] = [
      "active-newer": 2000.0,
      "active-older": 1000.0,
      "active-tie-a": 1500.0,
      "active-tie-b": 1500.0
    ]
    
    let sorted = IndexActivityService.sortIndicesByActivity(indices: indices, timestamps: timestamps)
    
    XCTAssertEqual(sorted, [
      "active-newer",
      "active-tie-a",
      "active-tie-b",
      "active-older",
      "dateless-a",
      "dateless-b"
    ])
  }

  @Test func testIndexActivityService_jsonEscaping() {
    let escaped = IndexActivityService.escapeJsonString("field\\with\"special")
    XCTAssertEqual(escaped, "field\\\\with\\\"special")
    let query = IndexActivityService.buildSingleIndexMaxQuery(field: "field\\with\"special")
    XCTAssertTrue(query.contains("\"field\\\\with\\\"special\""))
  }

  @Test func testIndexActivityService_secondsNormalization() {
    // 1700000000 s = 1700000000000 ms
    let secondsJSON = """
    {
      "aggregations": {
        "max_date": {
          "value": 1700000000
        }
      }
    }
    """.data(using: .utf8)!

    let normalized = IndexActivityService.parseSingleMaxTimestamp(data: secondsJSON, isNanos: false, isSeconds: true)
    XCTAssertEqual(normalized, 1700000000000.0)
  }

  @Test func testIndexActivityService_epochSecondsExtraction() {
    let mappingJSON = """
    {
      "events": {
        "mappings": {
          "properties": {
            "created": {
              "type": "date",
              "format": "epoch_second"
            },
            "timestamp": {
              "type": "date"
            }
          }
        }
      }
    }
    """.data(using: .utf8)!

    let parsed = IndexActivityService.parseDateFieldsByIndices(from: mappingJSON, targetIndices: ["events"])
    let fields = parsed["events"] ?? []
    let createdField = fields.first { $0.name == "created" }
    let timestampField = fields.first { $0.name == "timestamp" }

    XCTAssertEqual(createdField?.isSeconds, true)
    XCTAssertEqual(timestampField?.isSeconds, false)
  }

  @Test func testSideBarManageCase() {
    var currentSidebar: sideBar = .hidden
    XCTAssertEqual(currentSidebar, .hidden)
    currentSidebar = .manage
    XCTAssertEqual(currentSidebar, .manage)
    XCTAssertNotEqual(currentSidebar, .hosts)
    XCTAssertNotEqual(currentSidebar, .settings)
    XCTAssertNotEqual(currentSidebar, .develop)
  }

#if os(macOS)
  @Test @MainActor func testManageNavigationCoordinator_initialState() {
    let coordinator = ManageNavigationCoordinator()
    XCTAssertEqual(coordinator.screen, .hostList)
    XCTAssertNil(coordinator.selectedHost)
  }

  @Test @MainActor func testManageNavigationCoordinator_navigationFlow() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()
    host.name = "Cluster A"
    host.env = "Prod"

    coordinator.selectHost(host)
    XCTAssertEqual(coordinator.screen, .hostOptions)
    XCTAssertEqual(coordinator.selectedHost?.name, "Cluster A")

    coordinator.navigateToListIndexes()
    XCTAssertEqual(coordinator.screen, .indexList)

    coordinator.goBack()
    XCTAssertEqual(coordinator.screen, .hostOptions)
    XCTAssertEqual(coordinator.selectedHost?.name, "Cluster A")

    coordinator.goBack()
    XCTAssertEqual(coordinator.screen, .hostList)
    XCTAssertNil(coordinator.selectedHost)
  }

  @Test @MainActor func testManageNavigationCoordinator_validateCurrentHost() {
    let coordinator = ManageNavigationCoordinator()
    let host1 = HostDetails()
    host1.name = "Cluster 1"
    let host2 = HostDetails()
    host2.name = "Cluster 2"

    coordinator.selectHost(host1)
    coordinator.navigateToListIndexes()

    // When host1 exists in active list, coordinator remains on indexList
    coordinator.validateCurrentHost(against: [host1, host2])
    XCTAssertEqual(coordinator.screen, .indexList)
    XCTAssertEqual(coordinator.selectedHost?.name, "Cluster 1")

    // When host1 is removed from active list, coordinator resets to hostList
    coordinator.validateCurrentHost(against: [host2])
    XCTAssertEqual(coordinator.screen, .hostList)
    XCTAssertNil(coordinator.selectedHost)
  }

  @Test @MainActor func testManageNavigationCoordinator_validateInvalidatedHost() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()
    host.name = "Cluster 1"

    coordinator.selectHost(host)
    XCTAssertEqual(coordinator.screen, .hostOptions)

    // When active list doesn't include host, resets to hostList
    coordinator.validateCurrentHost(against: [])
    XCTAssertEqual(coordinator.screen, .hostList)
    XCTAssertNil(coordinator.selectedHost)
  }

  @Test @MainActor func testManageNavigationCoordinator_goBackAtRoot() {
    let coordinator = ManageNavigationCoordinator()
    XCTAssertEqual(coordinator.screen, .hostList)
    XCTAssertNil(coordinator.selectedHost)

    // goBack at root should be a no-op
    coordinator.goBack()
    XCTAssertEqual(coordinator.screen, .hostList)
    XCTAssertNil(coordinator.selectedHost)
  }

  @Test @MainActor func testManageNavigationCoordinator_reset() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()
    host.name = "Cluster Reset"

    coordinator.selectHost(host)
    coordinator.navigateToListIndexes()
    XCTAssertEqual(coordinator.screen, .indexList)
    XCTAssertNotNil(coordinator.selectedHost)

    coordinator.reset()
    XCTAssertEqual(coordinator.screen, .hostList)
    XCTAssertNil(coordinator.selectedHost)
  }
#endif

  @Test func testGetIndexArray_elasticErrorFormat() {
    let errorJson = """
    {
      "error": {
        "root_cause": [
          {
            "type": "index_not_found_exception",
            "reason": "no such index [missing-index]"
          }
        ],
        "type": "index_not_found_exception",
        "reason": "no such index [missing-index]"
      },
      "status": 404
    }
    """
    let result = Results.getIndexArray(errorJson)
    XCTAssertEqual(result.error, "no such index [missing-index]")
    XCTAssertTrue(result.data.isEmpty)
  }

  @Test func testGetIndexArray_elasticErrorWithoutRootCause() {
    let errorJson = """
    {
      "error": {
        "type": "security_exception",
        "reason": "action [indices:admin/aliases/get] is unauthorized for user [viewer]"
      },
      "status": 403
    }
    """
    let result = Results.getIndexArray(errorJson)
    XCTAssertEqual(result.error, "action [indices:admin/aliases/get] is unauthorized for user [viewer]")
    XCTAssertTrue(result.data.isEmpty)
  }

  @Test func testGetIndexArray_elasticErrorString() {
    let errorJson = """
    {
      "error": "Incorrect HTTP method for uri [/_aliases] and method [POST], allowed: [GET, HEAD]"
    }
    """
    let result = Results.getIndexArray(errorJson)
    XCTAssertEqual(result.error, "Incorrect HTTP method for uri [/_aliases] and method [POST], allowed: [GET, HEAD]")
    XCTAssertFalse(result.data.contains("error"), "Should not treat 'error' field as an index name")
    XCTAssertTrue(result.data.isEmpty)
  }

  @Test func testGetIndexArray_alternativeErrorFormat() {
    let errorJson = """
    {
      "message": "Cluster unavailable",
      "ok": false
    }
    """
    let result = Results.getIndexArray(errorJson)
    XCTAssertEqual(result.error, "Cluster unavailable")
    XCTAssertTrue(result.data.isEmpty)
  }

  @Test func testGetIndexArray_successAndHiddenFilter() {
    let successJson = """
    {
      "logs-2025.01": { "aliases": {} },
      "metrics-2025.01": { "aliases": {} },
      ".kibana_1": { "aliases": {} }
    }
    """
    let result = Results.getIndexArray(successJson)
    XCTAssertNil(result.error)
    XCTAssertTrue(result.data.contains("logs-2025.01"))
    XCTAssertTrue(result.data.contains("metrics-2025.01"))
    XCTAssertFalse(result.data.contains(".kibana_1"))
  }

  @Test func testHostDetails_generateCopy_deepCopyIndependence() {
    let original = HostDetails()
    original.name = "Cluster Original"
    let hostUrl = HostURL()
    hostUrl.url = "https://es.example.com"
    hostUrl.scheme = .HTTPS
    original.host = hostUrl

    let header = Headers()
    header.header = "X-Test"
    header.value = "123"
    original.customHeaders.append(header)

    let copy = original.generateCopy()
    XCTAssertEqual(copy.name, "Cluster Original")
    XCTAssertEqual(copy.host?.url, "https://es.example.com")
    XCTAssertFalse(copy.host === original.host, "HostURL should be an independent instance")
    XCTAssertFalse(copy.customHeaders === original.customHeaders, "Headers list should be an independent instance")
    XCTAssertEqual(copy.customHeaders.count, 1)
    XCTAssertEqual(copy.customHeaders.first?.header, "X-Test")
  }

  @Test func testGetIndexArray_hiddenDataPopulated() {
    let inputJson = """
    {
      "logs-2025.01": { "aliases": {} },
      "metrics-prod": { "aliases": {} },
      ".kibana_1": { "aliases": {} },
      ".security-7": { "aliases": {} },
      ".ds-ilm-history-5-2025": { "aliases": {} }
    }
    """
    let result = Results.getIndexArray(inputJson)
    XCTAssertNil(result.error)
    XCTAssertEqual(Set(result.data), Set(["logs-2025.01", "metrics-prod"]))
    XCTAssertEqual(Set(result.hiddenData), Set([".kibana_1", ".security-7", ".ds-ilm-history-5-2025"]))
  }

  @Test func testParseIndexStats_success() {
    let statsJson = """
    {
      "_shards": { "total": 2, "successful": 2, "failed": 0 },
      "_all": {
        "primaries": {
          "docs": { "count": 1500, "deleted": 12 },
          "store": { "size_in_bytes": 1048576 }
        },
        "total": {
          "docs": { "count": 3000, "deleted": 24 },
          "store": { "size_in_bytes": 2097152 }
        }
      },
      "indices": {
        "my-index": {
          "primaries": {
            "docs": { "count": 100, "deleted": 5 },
            "store": { "size_in_bytes": 1024 }
          },
          "total": {
            "docs": { "count": 200, "deleted": 10 },
            "store": { "size_in_bytes": 2048 }
          }
        },
        ".kibana_1": {
          "primaries": {
            "docs": { "count": 42, "deleted": 0 },
            "store": { "size_in_bytes": 51200 }
          },
          "total": {
            "docs": { "count": 42, "deleted": 0 },
            "store": { "size_in_bytes": 51200 }
          }
        }
      }
    }
    """
    let stats = Results.parseIndexStats(statsJson)
    XCTAssertEqual(stats.count, 2)

    let myIndex = stats["my-index"]
    XCTAssertNotNil(myIndex)
    XCTAssertEqual(myIndex?.docCount, 100)
    XCTAssertEqual(myIndex?.storageBytes, 1024)
    XCTAssertEqual(myIndex?.totalDocCount, 200)
    XCTAssertEqual(myIndex?.totalStorageBytes, 2048)
    XCTAssertEqual(myIndex?.deletedDocCount, 5)

    let kibanaIndex = stats[".kibana_1"]
    XCTAssertNotNil(kibanaIndex)
    XCTAssertEqual(kibanaIndex?.docCount, 42)
    XCTAssertEqual(kibanaIndex?.storageBytes, 51200)
    XCTAssertEqual(kibanaIndex?.totalDocCount, 42)
    XCTAssertEqual(kibanaIndex?.totalStorageBytes, 51200)
    XCTAssertEqual(kibanaIndex?.deletedDocCount, 0)
  }

  @Test func testParseIndexStats_skipsMetaKeys() {
    let statsJson = """
    {
      "_shards": { "total": 1, "successful": 1, "failed": 0 },
      "_all": {
        "primaries": { "docs": { "count": 50 } }
      },
      "indices": {
        "_all": { "primaries": { "docs": { "count": 50 } } },
        "_shards": { "total": 1 },
        "_other_meta": { "primaries": { "docs": { "count": 1 } } },
        "valid-index": {
          "primaries": {
            "docs": { "count": 25, "deleted": 2 },
            "store": { "size_in_bytes": 4096 }
          }
        }
      }
    }
    """
    let stats = Results.parseIndexStats(statsJson)
    XCTAssertEqual(stats.count, 1)
    XCTAssertNotNil(stats["valid-index"])
    XCTAssertNil(stats["_all"])
    XCTAssertNil(stats["_shards"])
    XCTAssertNil(stats["_other_meta"])
  }

  @Test func testParseIndexStats_missingOrClosedIndex() {
    let statsJson = """
    {
      "indices": {
        "open-index": {
          "primaries": {
            "docs": { "count": 10, "deleted": 1 },
            "store": { "size_in_bytes": 2048 }
          }
        },
        "closed-index": {
          "primaries": {},
          "total": {}
        }
      }
    }
    """
    let stats = Results.parseIndexStats(statsJson)
    XCTAssertEqual(stats.count, 2)
    XCTAssertEqual(stats["open-index"]?.docCount, 10)
    XCTAssertEqual(stats["open-index"]?.storageBytes, 2048)

    let closed = stats["closed-index"]
    XCTAssertNotNil(closed)
    XCTAssertNil(closed?.docCount)
    XCTAssertNil(closed?.storageBytes)
    XCTAssertNil(closed?.formattedDocCount)
    XCTAssertNil(closed?.formattedStorageSize)

    // Index not in stats JSON at all
    XCTAssertNil(stats["missing-index"])
  }

  @Test func testParseIndexStats_onlyTotalOrOnlyPrimaries() {
    let statsJson = """
    {
      "indices": {
        "only-primaries": {
          "primaries": {
            "docs": { "count": 75, "deleted": 3 },
            "store": { "size_in_bytes": 8192 }
          }
        },
        "only-total": {
          "total": {
            "docs": { "count": 150, "deleted": 6 },
            "store": { "size_in_bytes": 16384 }
          }
        }
      }
    }
    """
    let stats = Results.parseIndexStats(statsJson)
    XCTAssertEqual(stats["only-primaries"]?.docCount, 75)
    XCTAssertEqual(stats["only-primaries"]?.storageBytes, 8192)
    XCTAssertNil(stats["only-primaries"]?.totalDocCount)

    XCTAssertEqual(stats["only-total"]?.docCount, 150)
    XCTAssertEqual(stats["only-total"]?.storageBytes, 16384)
    XCTAssertEqual(stats["only-total"]?.totalDocCount, 150)
  }

  @Test func testIndexStatsItem_formatters() {
    let zeroDocs = IndexStatsItem(docCount: 0, storageBytes: 0)
    XCTAssertEqual(zeroDocs.formattedDocCount, "0 docs")
    XCTAssertEqual(zeroDocs.formattedStorageSize, "0 bytes")

    let oneDoc = IndexStatsItem(docCount: 1, storageBytes: 1_200_000)
    XCTAssertEqual(oneDoc.formattedDocCount, "1 doc")
    XCTAssertEqual(oneDoc.formattedStorageSize, "1.2 MB")

    let tenThousandDocs = IndexStatsItem(docCount: 10_000, storageBytes: 10_485_760)
    XCTAssertEqual(tenThousandDocs.formattedDocCount, "10,000 docs")

    let nilItem = IndexStatsItem(docCount: nil, storageBytes: nil)
    XCTAssertNil(nilItem.formattedDocCount)
    XCTAssertNil(nilItem.formattedStorageSize)
  }

  @Test func testParseIndexStats_errorPayloadReturnsEmpty() {
    let standardErrorJson = """
    {
      "error": {
        "root_cause": [
          {
            "type": "security_exception",
            "reason": "action [indices:monitor/stats] is unauthorized"
          }
        ],
        "type": "security_exception",
        "reason": "action [indices:monitor/stats] is unauthorized"
      },
      "status": 403
    }
    """
    let standardResult = Results.parseIndexStats(standardErrorJson)
    XCTAssertTrue(standardResult.isEmpty, "Error JSON should return empty dictionary, not an 'error' index entry")

    let alternativeErrorJson = """
    {
      "message": "Cluster unavailable",
      "ok": false
    }
    """
    let alternativeResult = Results.parseIndexStats(alternativeErrorJson)
    XCTAssertTrue(alternativeResult.isEmpty, "Alternative error JSON should return empty dictionary")

    let emptyResult = Results.parseIndexStats("")
    XCTAssertTrue(emptyResult.isEmpty)

    let invalidJsonResult = Results.parseIndexStats("not json at all")
    XCTAssertTrue(invalidJsonResult.isEmpty)
  }

  @Test func testIndexStatsItem_negativeAndLargeValues() {
    let negativeDocs = IndexStatsItem(docCount: -5, storageBytes: 1024)
    XCTAssertNil(negativeDocs.formattedDocCount, "Negative doc count should return nil")
    XCTAssertNotNil(negativeDocs.formattedStorageSize)

    let negativeStorage = IndexStatsItem(docCount: 10, storageBytes: -100)
    XCTAssertEqual(negativeStorage.formattedDocCount, "10 docs")
    XCTAssertNil(negativeStorage.formattedStorageSize, "Negative storage size should return nil")

    let largeDocCount = IndexStatsItem(docCount: 3_000_000_000, storageBytes: 107_374_182_400)
    XCTAssertEqual(largeDocCount.formattedDocCount, "3,000,000,000 docs")
    XCTAssertEqual(largeDocCount.formattedStorageSize, "107.37 GB")
  }

  @Test func testIndexFilter_hiddenIndicesFiltering() {
    let hiddenIndices = [".kibana_1", ".kibana_task_manager", ".security-7", ".ds-ilm-history-5"]

    let kibanaMatches = IndexFilterHelper.filter(indices: hiddenIndices, query: "kibana")
    XCTAssertEqual(Set(kibanaMatches), Set([".kibana_1", ".kibana_task_manager"]))

    let wildcardMatches = IndexFilterHelper.filter(indices: hiddenIndices, query: ".*kibana*")
    XCTAssertEqual(Set(wildcardMatches), Set([".kibana_1", ".kibana_task_manager"]))

    let securityMatches = IndexFilterHelper.filter(indices: hiddenIndices, query: "*.security*")
    XCTAssertEqual(securityMatches, [".security-7"])

    let noMatches = IndexFilterHelper.filter(indices: hiddenIndices, query: "logs")
    XCTAssertTrue(noMatches.isEmpty)
  }
}
