// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import Testing

@testable import Search_Ops

struct SearchOpsUnitTests {
  
  @Test func testEquality() {
    let field1 = FieldsArray(name: "FieldA")
    let field2 = FieldsArray(name: "FieldA")
    #expect(field1 == field2, "FieldsArray instances with the same name should be equal")
  }

  @Test func testIndexFilter_emptyAndWhitespaceQuery() {
    let indices = ["logs-2025", "audit", "metrics"]
    #expect(IndexFilterHelper.filter(indices: indices, query: "") == ["audit", "logs-2025", "metrics"])
    #expect(IndexFilterHelper.filter(indices: indices, query: "   \n") == ["audit", "logs-2025", "metrics"])
  }

  @Test func testIndexFilter_caseInsensitiveSubstring() {
    let indices = ["audit-log", "APP-LOGS", "metrics-2025", "system"]
    let filtered = IndexFilterHelper.filter(indices: indices, query: "log")
    #expect(filtered == ["APP-LOGS", "audit-log"])
  }

  @Test func testIndexFilter_wildcardAsterisk() {
    let indices = ["logs-2025-01", "logs-2024-12", "metrics-logs", "audit"]
    let filteredPrefix = IndexFilterHelper.filter(indices: indices, query: "logs-*")
    #expect(filteredPrefix == ["logs-2024-12", "logs-2025-01"])

    let filteredSuffix = IndexFilterHelper.filter(indices: indices, query: "*logs")
    #expect(filteredSuffix == ["metrics-logs"])
  }

  @Test func testIndexFilter_wildcardQuestionMark() {
    let indices = ["log1", "log2", "log10", "other"]
    let filtered = IndexFilterHelper.filter(indices: indices, query: "log?")
    #expect(filtered == ["log1", "log2"])
  }

  @Test func testIndexFilter_specialCharactersEscaped() {
    let indices = ["app.prod", "appXprod", "data(old)", "data_new"]
    let filteredDot = IndexFilterHelper.filter(indices: indices, query: "app.prod")
    #expect(filteredDot == ["app.prod"])

    let filteredParens = IndexFilterHelper.filter(indices: indices, query: "(old)")
    #expect(filteredParens == ["data(old)"])
  }

  @Test func testIndexFilter_deduplicationAndEmpty() {
    let duplicateIndices = ["audit", "audit", "metrics", "audit"]
    #expect(IndexFilterHelper.filter(indices: duplicateIndices, query: "") == ["audit", "metrics"])

    let emptyIndices: [String] = []
    #expect(IndexFilterHelper.filter(indices: emptyIndices, query: "logs") == [])
  }

  @Test func testIndexFilter_noMatches() {
    let indices = ["logs", "metrics", "traces"]
    #expect(IndexFilterHelper.filter(indices: indices, query: "k8s") == [])
  }

  @Test func testIndexFilter_showAllButton() {
    #expect(IndexFilterHelper.showAllButton(query: ""))
    #expect(IndexFilterHelper.showAllButton(query: "   "))
    #expect(IndexFilterHelper.showAllButton(query: "all"))
    #expect(IndexFilterHelper.showAllButton(query: "_all"))
    #expect(IndexFilterHelper.showAllButton(query: "_ALL"))
    #expect(IndexFilterHelper.showAllButton(query: "*all*"))
    #expect(!(IndexFilterHelper.showAllButton(query: "logs")))
    #expect(!(IndexFilterHelper.showAllButton(query: "audit")))
  }

  @Test func testIndexFilter_excludesAllPseudoIndex() {
    let indicesWithAll = ["_all", "audit", "metrics"]
    let filtered = IndexFilterHelper.filter(indices: indicesWithAll, query: "")
    #expect(filtered == ["audit", "metrics"])
    #expect(!(filtered.contains("_all")))

    let filteredSearch = IndexFilterHelper.filter(indices: indicesWithAll, query: "all")
    #expect(filteredSearch == [])
  }

  @Test func testIndexFilter_totalCount() {
    #expect(IndexFilterHelper.totalCount(indices: []) == 1)
    #expect(IndexFilterHelper.totalCount(indices: ["audit", "metrics"]) == 3)
    #expect(IndexFilterHelper.totalCount(indices: ["audit", "audit", "metrics"]) == 3)
    #expect(IndexFilterHelper.totalCount(indices: ["_all", "audit", "metrics"]) == 3)
    #expect(IndexFilterHelper.totalCount(indices: ["_all", "audit", "audit"]) == 2)
    #expect(IndexFilterHelper.totalCount(indices: [], includeAll: false) == 0)
    #expect(IndexFilterHelper.totalCount(indices: ["audit", "metrics"], includeAll: false) == 2)
    #expect(IndexFilterHelper.totalCount(indices: ["_all", "audit", "metrics"], includeAll: false) == 2)
  }

  @Test func testIndexFilter_consecutiveWildcards() {
    let indices = ["logs-2025-01", "logs-2024-12", "metrics"]
    let filteredDouble = IndexFilterHelper.filter(indices: indices, query: "logs**01")
    #expect(filteredDouble == ["logs-2025-01"])

    let filteredTriple = IndexFilterHelper.filter(indices: indices, query: "***metrics***")
    #expect(filteredTriple == ["metrics"])
  }

  @Test func testIndexFilter_complexPatterns() {
    let indices = ["k8s-prod.logs", "k8s-dev.logs", "k8s-prod.metrics", "other"]
    let filtered = IndexFilterHelper.filter(indices: indices, query: "k8s-*.logs")
    #expect(filtered == ["k8s-dev.logs", "k8s-prod.logs"])

    let singleChar = IndexFilterHelper.filter(indices: ["cat", "cot", "coat", "cut"], query: "c?t")
    #expect(singleChar == ["cat", "cot", "cut"])
  }

  @Test func testIndexFilter_preserveOrderDeduplication() {
    let customOrder = ["zebra-index", "alpha-index", "beta-index", "alpha-index", "_all"]
    let filteredDefault = IndexFilterHelper.filter(indices: customOrder, query: "")
    // Default alphabetical sorting
    #expect(filteredDefault == ["alpha-index", "beta-index", "zebra-index"])
    
    // preserveOrder: true keeps incoming order and deduplicates, excludes _all
    let filteredPreserved = IndexFilterHelper.filter(indices: customOrder, query: "", preserveOrder: true)
    #expect(filteredPreserved == ["zebra-index", "alpha-index", "beta-index"])
    
    // With query filter and preserveOrder
    let withQuery = IndexFilterHelper.filter(indices: customOrder, query: "a-index", preserveOrder: true)
    #expect(withQuery == ["zebra-index", "alpha-index", "beta-index"])
  }

  @Test func testIndexFilter_displayLimitingAndBoundary() {
    #expect(IndexFilterHelper.defaultDisplayLimit == 30)
    
    let empty: [String] = []
    #expect(IndexFilterHelper.limitIndices(empty) == [])
    #expect(!(IndexFilterHelper.hasExceededLimit(empty)))
    
    let fifteen = (1...15).map { "index-\($0)" }
    #expect(IndexFilterHelper.limitIndices(fifteen).count == 15)
    #expect(!(IndexFilterHelper.hasExceededLimit(fifteen)))
    
    let thirty = (1...30).map { "index-\($0)" }
    #expect(IndexFilterHelper.limitIndices(thirty).count == 30)
    #expect(!(IndexFilterHelper.hasExceededLimit(thirty)))
    
    let thirtyOne = (1...31).map { "index-\($0)" }
    #expect(IndexFilterHelper.limitIndices(thirtyOne).count == 30)
    #expect(IndexFilterHelper.limitIndices(thirtyOne) == Array(thirtyOne.prefix(30)))
    #expect(IndexFilterHelper.hasExceededLimit(thirtyOne))
    
    let fifty = (1...50).map { "index-\($0)" }
    #expect(IndexFilterHelper.limitIndices(fifty).count == 30)
    #expect(IndexFilterHelper.hasExceededLimit(fifty))
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
    #expect(parsed["system-index"] == nil)
    
    let v8Fields = parsed["logs-v8"] ?? []
    #expect(v8Fields.contains(DateFieldInfo(name: "@timestamp", isNanos: false)))
    #expect(v8Fields.contains(DateFieldInfo(name: "user.created_at", isNanos: true)))
    #expect(!(v8Fields.contains(DateFieldInfo(name: "message", isNanos: false))))
    
    let v6Fields = parsed["logs-v6"] ?? []
    #expect(v6Fields.contains(DateFieldInfo(name: "timestamp", isNanos: false)))
  }

  @Test func testIndexActivityService_datePriority() {
    let fields = [
      DateFieldInfo(name: "created_at", isNanos: false),
      DateFieldInfo(name: "@timestamp", isNanos: false),
      DateFieldInfo(name: "updated_at", isNanos: false)
    ]
    let best = IndexActivityService.selectBestDateField(from: fields)
    #expect(best?.name == "@timestamp")
    
    let fieldsWithoutAt = [
      DateFieldInfo(name: "created_at", isNanos: false),
      DateFieldInfo(name: "updated_at", isNanos: false),
      DateFieldInfo(name: "random_field", isNanos: false)
    ]
    let bestSecond = IndexActivityService.selectBestDateField(from: fieldsWithoutAt)
    #expect(bestSecond?.name == "updated_at")
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
    #expect(normalized == 1700000000000.0)
    
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
    #expect(standard == 1700000000000.0)
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
    #expect(timestamps["idx-1"] == 1705000000000.0)
    #expect(timestamps["idx-2"] == 1704000000000.0)
    #expect(timestamps["idx-empty"] == nil)
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
    
    #expect(sorted == [
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
    #expect(escaped == "field\\\\with\\\"special")
    let query = IndexActivityService.buildSingleIndexMaxQuery(field: "field\\with\"special")
    #expect(query.contains("\"field\\\\with\\\"special\""))
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
    #expect(normalized == 1700000000000.0)
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

    #expect(createdField?.isSeconds == true)
    #expect(timestampField?.isSeconds == false)
  }

#if os(macOS)
  @Test @MainActor func testManageNavigationCoordinator_initialState() {
    let coordinator = ManageNavigationCoordinator()
    #expect(coordinator.screen == .hostList)
    #expect(coordinator.selectedHost == nil)
  }

  @Test @MainActor func testManageNavigationCoordinator_navigationFlow() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()
    host.name = "Cluster A"
    host.env = "Prod"

    coordinator.selectHost(host)
    #expect(coordinator.screen == .hostOptions)
    #expect(coordinator.selectedHost?.name == "Cluster A")

    coordinator.navigateToListIndexes()
    #expect(coordinator.screen == .indexList)

    coordinator.goBack()
    #expect(coordinator.screen == .hostOptions)
    #expect(coordinator.selectedHost?.name == "Cluster A")

    coordinator.goBack()
    #expect(coordinator.screen == .hostList)
    #expect(coordinator.selectedHost == nil)
  }

  @Test @MainActor func testManageNavigationCoordinator_listUsersFlow() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()
    host.name = "Cluster A"

    coordinator.selectHost(host)
    coordinator.navigateToListUsers()
    #expect(coordinator.screen == .userList)

    coordinator.goBack()
    #expect(coordinator.screen == .hostOptions)
    #expect(coordinator.selectedHost?.name == "Cluster A")
  }

  @Test @MainActor func testManageNavigationCoordinator_clusterHealthFlow() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()
    host.name = "Cluster A"

    coordinator.selectHost(host)
    coordinator.navigateToClusterHealth()
    #expect(coordinator.screen == .clusterHealth)

    coordinator.goBack()
    #expect(coordinator.screen == .hostOptions)
    #expect(coordinator.selectedHost?.name == "Cluster A")
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
    #expect(coordinator.screen == .indexList)
    #expect(coordinator.selectedHost?.name == "Cluster 1")

    // When host1 is removed from active list, coordinator resets to hostList
    coordinator.validateCurrentHost(against: [host2])
    #expect(coordinator.screen == .hostList)
    #expect(coordinator.selectedHost == nil)
  }

  @Test @MainActor func testManageNavigationCoordinator_validateInvalidatedHost() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()
    host.name = "Cluster 1"

    coordinator.selectHost(host)
    #expect(coordinator.screen == .hostOptions)

    // When active list doesn't include host, resets to hostList
    coordinator.validateCurrentHost(against: [])
    #expect(coordinator.screen == .hostList)
    #expect(coordinator.selectedHost == nil)
  }

  @Test @MainActor func testManageNavigationCoordinator_goBackAtRoot() {
    let coordinator = ManageNavigationCoordinator()
    #expect(coordinator.screen == .hostList)
    #expect(coordinator.selectedHost == nil)

    // goBack at root should be a no-op
    coordinator.goBack()
    #expect(coordinator.screen == .hostList)
    #expect(coordinator.selectedHost == nil)
  }

  @Test @MainActor func testManageNavigationCoordinator_reset() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()
    host.name = "Cluster Reset"

    coordinator.selectHost(host)
    coordinator.navigateToListIndexes()
    #expect(coordinator.screen == .indexList)
    #expect(coordinator.selectedHost != nil)

    coordinator.reset()
    #expect(coordinator.screen == .hostList)
    #expect(coordinator.selectedHost == nil)
  }

  @Test @MainActor func testManageNavigationCoordinator_dataViewsFlow() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()
    host.name = "Cluster A"
    let viewId = UUID()

    coordinator.selectHost(host)
    coordinator.navigateToDataViews()
    #expect(coordinator.screen == .dataViewList)

    coordinator.editDataView(viewId)
    #expect(coordinator.screen == .dataViewEditor)
    #expect(coordinator.selectedDataViewId == viewId)

    coordinator.goBack()
    #expect(coordinator.screen == .dataViewList)
    #expect(coordinator.selectedDataViewId == nil)

    // nil opens the editor for a new view
    coordinator.editDataView(nil)
    #expect(coordinator.screen == .dataViewEditor)
    #expect(coordinator.selectedDataViewId == nil)

    coordinator.goBack()
    coordinator.goBack()
    #expect(coordinator.screen == .hostOptions)
    #expect(coordinator.selectedHost?.name == "Cluster A")
  }

  @Test @MainActor func testManageNavigationCoordinator_openNewDataView() {
    let coordinator = ManageNavigationCoordinator()
    let oldHost = HostDetails()
    oldHost.name = "Cluster A"
    let host = HostDetails()
    host.name = "Cluster B"

    // Left on another host's index from an earlier visit
    coordinator.selectHost(oldHost)
    coordinator.selectIndex("logs")

    coordinator.openNewDataView(for: host)
    #expect(coordinator.screen == .dataViewEditor)
    #expect(coordinator.selectedHost?.name == "Cluster B")
    #expect(coordinator.selectedDataViewId == nil)
    #expect(coordinator.selectedIndex == nil)

    // Back goes to that host's data views, then its options
    coordinator.goBack()
    #expect(coordinator.screen == .dataViewList)
    coordinator.goBack()
    #expect(coordinator.screen == .hostOptions)
    #expect(coordinator.selectedHost?.name == "Cluster B")
  }

  @Test @MainActor func testManageNavigationCoordinator_resetAfterOpenNewDataView() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()

    coordinator.openNewDataView(for: host)
    coordinator.editDataView(UUID())

    // Leaving the Hosts tab resets it
    coordinator.reset()
    #expect(coordinator.screen == .hostList)
    #expect(coordinator.selectedHost == nil)
    #expect(coordinator.selectedDataViewId == nil)
  }

  @Test @MainActor func testManageNavigationCoordinator_removedHostClosesDataViewEditor() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()

    coordinator.selectHost(host)
    coordinator.navigateToDataViews()
    coordinator.editDataView(UUID())

    coordinator.validateCurrentHost(against: [])
    #expect(coordinator.screen == .hostList)
    #expect(coordinator.selectedDataViewId == nil)
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
    #expect(result.error == "no such index [missing-index]")
    #expect(result.data.isEmpty)
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
    #expect(result.error == "action [indices:admin/aliases/get] is unauthorized for user [viewer]")
    #expect(result.data.isEmpty)
  }

  @Test func testGetIndexArray_elasticErrorString() {
    let errorJson = """
    {
      "error": "Incorrect HTTP method for uri [/_aliases] and method [POST], allowed: [GET, HEAD]"
    }
    """
    let result = Results.getIndexArray(errorJson)
    #expect(result.error == "Incorrect HTTP method for uri [/_aliases] and method [POST], allowed: [GET, HEAD]")
    #expect(!(result.data.contains("error")), "Should not treat 'error' field as an index name")
    #expect(result.data.isEmpty)
  }

  @Test func testGetIndexArray_alternativeErrorFormat() {
    let errorJson = """
    {
      "message": "Cluster unavailable",
      "ok": false
    }
    """
    let result = Results.getIndexArray(errorJson)
    #expect(result.error == "Cluster unavailable")
    #expect(result.data.isEmpty)
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
    #expect(result.error == nil)
    #expect(result.data.contains("logs-2025.01"))
    #expect(result.data.contains("metrics-2025.01"))
    #expect(!(result.data.contains(".kibana_1")))
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
    #expect(copy.name == "Cluster Original")
    #expect(copy.host?.url == "https://es.example.com")
    #expect(!(copy.host === original.host), "HostURL should be an independent instance")
    #expect(!(copy.customHeaders === original.customHeaders), "Headers list should be an independent instance")
    #expect(copy.customHeaders.count == 1)
    #expect(copy.customHeaders.first?.header == "X-Test")
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
    #expect(result.error == nil)
    #expect(Set(result.data) == Set(["logs-2025.01", "metrics-prod"]))
    #expect(Set(result.hiddenData) == Set([".kibana_1", ".security-7", ".ds-ilm-history-5-2025"]))
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
    #expect(stats.count == 2)

    let myIndex = stats["my-index"]
    #expect(myIndex != nil)
    #expect(myIndex?.docCount == 100)
    #expect(myIndex?.storageBytes == 1024)
    #expect(myIndex?.totalDocCount == 200)
    #expect(myIndex?.totalStorageBytes == 2048)
    #expect(myIndex?.deletedDocCount == 5)

    let kibanaIndex = stats[".kibana_1"]
    #expect(kibanaIndex != nil)
    #expect(kibanaIndex?.docCount == 42)
    #expect(kibanaIndex?.storageBytes == 51200)
    #expect(kibanaIndex?.totalDocCount == 42)
    #expect(kibanaIndex?.totalStorageBytes == 51200)
    #expect(kibanaIndex?.deletedDocCount == 0)
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
    #expect(stats.count == 1)
    #expect(stats["valid-index"] != nil)
    #expect(stats["_all"] == nil)
    #expect(stats["_shards"] == nil)
    #expect(stats["_other_meta"] == nil)
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
    #expect(stats.count == 2)
    #expect(stats["open-index"]?.docCount == 10)
    #expect(stats["open-index"]?.storageBytes == 2048)

    let closed = stats["closed-index"]
    #expect(closed != nil)
    #expect(closed?.docCount == nil)
    #expect(closed?.storageBytes == nil)
    #expect(closed?.formattedDocCount == nil)
    #expect(closed?.formattedStorageSize == nil)

    // Index not in stats JSON at all
    #expect(stats["missing-index"] == nil)
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
    #expect(stats["only-primaries"]?.docCount == 75)
    #expect(stats["only-primaries"]?.storageBytes == 8192)
    #expect(stats["only-primaries"]?.totalDocCount == nil)

    #expect(stats["only-total"]?.docCount == 150)
    #expect(stats["only-total"]?.storageBytes == 16384)
    #expect(stats["only-total"]?.totalDocCount == 150)
  }

  @Test func testIndexStatsItem_formatters() {
    let zeroDocs = IndexStatsItem(docCount: 0, storageBytes: 0)
    #expect(zeroDocs.formattedDocCount == "0 docs")
    #expect(zeroDocs.formattedStorageSize == "0 bytes")

    let oneDoc = IndexStatsItem(docCount: 1, storageBytes: 1_200_000)
    #expect(oneDoc.formattedDocCount == "1 doc")
    #expect(oneDoc.formattedStorageSize == "1.2 MB")

    let tenThousandDocs = IndexStatsItem(docCount: 10_000, storageBytes: 10_485_760)
    #expect(tenThousandDocs.formattedDocCount == "10,000 docs")

    let nilItem = IndexStatsItem(docCount: nil, storageBytes: nil)
    #expect(nilItem.formattedDocCount == nil)
    #expect(nilItem.formattedStorageSize == nil)
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
    #expect(standardResult.isEmpty, "Error JSON should return empty dictionary, not an 'error' index entry")

    let alternativeErrorJson = """
    {
      "message": "Cluster unavailable",
      "ok": false
    }
    """
    let alternativeResult = Results.parseIndexStats(alternativeErrorJson)
    #expect(alternativeResult.isEmpty, "Alternative error JSON should return empty dictionary")

    let emptyResult = Results.parseIndexStats("")
    #expect(emptyResult.isEmpty)

    let invalidJsonResult = Results.parseIndexStats("not json at all")
    #expect(invalidJsonResult.isEmpty)
  }

  @Test func testIndexStatsItem_negativeAndLargeValues() {
    let negativeDocs = IndexStatsItem(docCount: -5, storageBytes: 1024)
    #expect(negativeDocs.formattedDocCount == nil, "Negative doc count should return nil")
    #expect(negativeDocs.formattedStorageSize != nil)

    let negativeStorage = IndexStatsItem(docCount: 10, storageBytes: -100)
    #expect(negativeStorage.formattedDocCount == "10 docs")
    #expect(negativeStorage.formattedStorageSize == nil, "Negative storage size should return nil")

    let largeDocCount = IndexStatsItem(docCount: 3_000_000_000, storageBytes: 107_374_182_400)
    #expect(largeDocCount.formattedDocCount == "3,000,000,000 docs")
    #expect(largeDocCount.formattedStorageSize == "107.37 GB")
  }

  @Test func testIndexFilter_hiddenIndicesFiltering() {
    let hiddenIndices = [".kibana_1", ".kibana_task_manager", ".security-7", ".ds-ilm-history-5"]

    let kibanaMatches = IndexFilterHelper.filter(indices: hiddenIndices, query: "kibana")
    #expect(Set(kibanaMatches) == Set([".kibana_1", ".kibana_task_manager"]))

    let wildcardMatches = IndexFilterHelper.filter(indices: hiddenIndices, query: ".*kibana*")
    #expect(Set(wildcardMatches) == Set([".kibana_1", ".kibana_task_manager"]))

    let securityMatches = IndexFilterHelper.filter(indices: hiddenIndices, query: "*.security*")
    #expect(securityMatches == [".security-7"])

    let noMatches = IndexFilterHelper.filter(indices: hiddenIndices, query: "logs")
    #expect(noMatches.isEmpty)
  }

  // MARK: - ManageIndexes Sorting Tests

  @Test func testManageIndexesSortOption_properties() {
    let options = ManageIndexesSortOption.allCases
    #expect(options.count == 4)
    #expect(options == [.name, .recent, .size, .docCount])

    #expect(ManageIndexesSortOption.name.id == "Name")
    #expect(ManageIndexesSortOption.name.iconName == "textformat")
    #expect(ManageIndexesSortOption.name.defaultAscending)
    #expect(!ManageIndexesSortOption.recent.defaultAscending)
    #expect(!ManageIndexesSortOption.size.defaultAscending)
    #expect(!ManageIndexesSortOption.docCount.defaultAscending)

    #expect(ManageIndexesSortOption.name.tooltip(isAscending: true).contains("A to Z"))
    #expect(ManageIndexesSortOption.name.tooltip(isAscending: false).contains("Z to A"))
    #expect(ManageIndexesSortOption.recent.tooltip(isAscending: false).contains("newest first"))
    #expect(ManageIndexesSortOption.recent.tooltip(isAscending: true).contains("oldest first"))
    #expect(ManageIndexesSortOption.size.tooltip(isAscending: false).contains("largest first"))
    #expect(ManageIndexesSortOption.size.tooltip(isAscending: true).contains("smallest first"))
    #expect(ManageIndexesSortOption.docCount.tooltip(isAscending: false).contains("highest first"))
    #expect(ManageIndexesSortOption.docCount.tooltip(isAscending: true).contains("lowest first"))

    #expect(!ManageIndexesSortOption.name.inactiveTooltip.isEmpty)
    #expect(!ManageIndexesSortOption.recent.inactiveTooltip.isEmpty)
    #expect(!ManageIndexesSortOption.size.inactiveTooltip.isEmpty)
    #expect(!ManageIndexesSortOption.docCount.inactiveTooltip.isEmpty)
  }

  @Test func testManageIndexesSortHelper_sortByName() {
    let indices = ["users", "audit-2025", "logs-app", "billing", "audit-2024"]

    let ascending = ManageIndexesSortHelper.sortIndices(
      indices: indices,
      sortOption: .name,
      ascending: true
    )
    #expect(ascending == ["audit-2024", "audit-2025", "billing", "logs-app", "users"])

    let descending = ManageIndexesSortHelper.sortIndices(
      indices: indices,
      sortOption: .name,
      ascending: false
    )
    #expect(descending == ["users", "logs-app", "billing", "audit-2025", "audit-2024"])

    // Deduplication & empty
    let withDupes = ["logs", "billing", "logs", "billing", "analytics"]
    let sortedDupes = ManageIndexesSortHelper.sortIndices(
      indices: withDupes,
      sortOption: .name,
      ascending: true
    )
    #expect(sortedDupes == ["analytics", "billing", "logs"])

    let empty = ManageIndexesSortHelper.sortIndices(
      indices: [],
      sortOption: .name,
      ascending: true
    )
    #expect(empty == [])
  }

  @Test func testManageIndexesSortHelper_sortBySize() {
    let indices = ["small", "huge", "medium", "unknown", "equal-b", "equal-a"]
    let stats: [String: IndexStatsItem] = [
      "small": IndexStatsItem(storageBytes: 1024),
      "huge": IndexStatsItem(storageBytes: 104_857_600),
      "medium": IndexStatsItem(storageBytes: 52_428_800),
      "equal-a": IndexStatsItem(storageBytes: 2048),
      "equal-b": IndexStatsItem(storageBytes: 2048),
      "unknown": IndexStatsItem(storageBytes: nil)
    ]

    // Descending: largest to smallest, nil stats at bottom, tie broken alphabetically
    let descending = ManageIndexesSortHelper.sortIndices(
      indices: indices,
      sortOption: .size,
      ascending: false,
      stats: stats
    )
    #expect(descending == ["huge", "medium", "equal-a", "equal-b", "small", "unknown"])

    // Ascending: smallest to largest, nil stats at bottom, tie broken alphabetically
    let ascending = ManageIndexesSortHelper.sortIndices(
      indices: indices,
      sortOption: .size,
      ascending: true,
      stats: stats
    )
    #expect(ascending == ["small", "equal-a", "equal-b", "medium", "huge", "unknown"])
  }

  @Test func testManageIndexesSortHelper_sortByDocCount() {
    let indices = ["ten", "million", "zero", "missing-stats", "hundred-b", "hundred-a"]
    let stats: [String: IndexStatsItem] = [
      "ten": IndexStatsItem(docCount: 10),
      "million": IndexStatsItem(docCount: 1_000_000),
      "zero": IndexStatsItem(docCount: 0),
      "hundred-a": IndexStatsItem(docCount: 100),
      "hundred-b": IndexStatsItem(docCount: 100)
    ]

    // Descending: most docs to least, nil stats at bottom, tie broken alphabetically
    let descending = ManageIndexesSortHelper.sortIndices(
      indices: indices,
      sortOption: .docCount,
      ascending: false,
      stats: stats
    )
    #expect(descending == ["million", "hundred-a", "hundred-b", "ten", "zero", "missing-stats"])

    // Ascending: least docs to most, nil stats at bottom, tie broken alphabetically
    let ascending = ManageIndexesSortHelper.sortIndices(
      indices: indices,
      sortOption: .docCount,
      ascending: true,
      stats: stats
    )
    #expect(ascending == ["zero", "ten", "hundred-a", "hundred-b", "million", "missing-stats"])
  }

  @Test func testManageIndexesSortHelper_sortByRecent() {
    let indices = ["yesterday", "now", "last-week", "no-activity", "same-b", "same-a"]
    let timestamps: [String: Double] = [
      "now": 1_726_800_000_000,
      "yesterday": 1_726_713_600_000,
      "last-week": 1_726_195_200_000,
      "same-a": 1_726_500_000_000,
      "same-b": 1_726_500_000_000
    ]

    // Descending: newest activity first, nil activity at bottom, tie broken alphabetically
    let descending = ManageIndexesSortHelper.sortIndices(
      indices: indices,
      sortOption: .recent,
      ascending: false,
      timestamps: timestamps
    )
    #expect(descending == ["now", "yesterday", "same-a", "same-b", "last-week", "no-activity"])

    // Ascending: oldest activity first, nil activity at bottom, tie broken alphabetically
    let ascending = ManageIndexesSortHelper.sortIndices(
      indices: indices,
      sortOption: .recent,
      ascending: true,
      timestamps: timestamps
    )
    #expect(ascending == ["last-week", "same-a", "same-b", "yesterday", "now", "no-activity"])
  }

  @Test func testManageIndexesSortHelper_formatters() {
    let referenceTime = Date(timeIntervalSince1970: 1_726_800_000) // 1726800000 seconds
    let oneHourAgoMs = (1_726_800_000.0 - 3600.0) * 1000.0

    let relString = ManageIndexesSortHelper.formatRelativeActivity(timestamp: oneHourAgoMs, relativeTo: referenceTime, locale: Locale(identifier: "en_US"))
    #expect(!relString.isEmpty)
    #expect(relString.contains("hr") || relString.contains("hour") || relString.contains("1"))

    let fullString = ManageIndexesSortHelper.formatFullActivity(timestamp: oneHourAgoMs, locale: Locale(identifier: "en_US"))
    #expect(!fullString.isEmpty)

    // Invalid timestamps
    #expect(ManageIndexesSortHelper.formatRelativeActivity(timestamp: 0) == "Unknown")
    #expect(ManageIndexesSortHelper.formatRelativeActivity(timestamp: -100) == "Unknown")
    #expect(ManageIndexesSortHelper.formatRelativeActivity(timestamp: Double.nan) == "Unknown")
    #expect(ManageIndexesSortHelper.formatRelativeActivity(timestamp: 1e15) == "Unknown")
    #expect(ManageIndexesSortHelper.formatFullActivity(timestamp: 0) == "Unknown")
    #expect(ManageIndexesSortHelper.formatFullActivity(timestamp: -500) == "Unknown")
    #expect(ManageIndexesSortHelper.formatFullActivity(timestamp: Double.infinity) == "Unknown")
    #expect(ManageIndexesSortHelper.formatFullActivity(timestamp: Double.greatestFiniteMagnitude) == "Unknown")
  }

  @Test func testManageIndexesSortHelper_negativeAndCorruptStats() {
    let indices = ["negative-docs", "negative-size", "valid-zero", "valid-positive", "corrupt-both"]
    let stats: [String: IndexStatsItem] = [
      "negative-docs": IndexStatsItem(docCount: -10, storageBytes: 5000),
      "negative-size": IndexStatsItem(docCount: 50, storageBytes: -200),
      "valid-zero": IndexStatsItem(docCount: 0, storageBytes: 0),
      "valid-positive": IndexStatsItem(docCount: 100, storageBytes: 10000),
      "corrupt-both": IndexStatsItem(docCount: -1, storageBytes: -1)
    ]

    // DocCount Ascending: valid 0, valid 50 (negative-size), valid 100, then negative/corrupt at bottom alphabetically
    let docAscending = ManageIndexesSortHelper.sortIndices(
      indices: indices,
      sortOption: .docCount,
      ascending: true,
      stats: stats
    )
    #expect(docAscending == ["valid-zero", "negative-size", "valid-positive", "corrupt-both", "negative-docs"])

    // Size Ascending: valid 0, valid 5000, valid 10000, then negative/corrupt at bottom alphabetically
    let sizeAscending = ManageIndexesSortHelper.sortIndices(
      indices: indices,
      sortOption: .size,
      ascending: true,
      stats: stats
    )
    #expect(sizeAscending == ["valid-zero", "negative-docs", "valid-positive", "corrupt-both", "negative-size"])

    // Recent with corrupt timestamps
    let timestamps: [String: Double] = [
      "valid-positive": 1_726_800_000_000,
      "valid-zero": 0, // invalid
      "negative-docs": -100_000, // invalid
      "negative-size": Double.nan, // invalid
      "corrupt-both": 1e16 // out-of-range
    ]
    let recentDesc = ManageIndexesSortHelper.sortIndices(
      indices: indices,
      sortOption: .recent,
      ascending: false,
      timestamps: timestamps
    )
    // Only valid-positive is valid, others are placed at bottom ordered alphabetically
    #expect(recentDesc.first == "valid-positive")
    #expect(Set(recentDesc.dropFirst()) == Set(["corrupt-both", "negative-docs", "negative-size", "valid-zero"]))
  }

#if os(macOS)
  @Test @MainActor func testManageNavigationCoordinator_indexDetailNavigation() {
    let coordinator = ManageNavigationCoordinator()
    let host = HostDetails()
    host.name = "Prod Cluster"
    coordinator.selectHost(host)
    coordinator.navigateToListIndexes()
    #expect(coordinator.screen == .indexList)

    let stats = IndexStatsItem(docCount: 500, storageBytes: 1024)
    coordinator.selectIndex("logs-2026", stats: stats)
    #expect(coordinator.screen == .indexDetail)
    #expect(coordinator.selectedIndex == "logs-2026")
    #expect(coordinator.selectedIndexStats?.docCount == 500)

    // goBack from indexDetail returns to indexList and clears index selection
    coordinator.goBack()
    #expect(coordinator.screen == .indexList)
    #expect(coordinator.selectedIndex == nil)
    #expect(coordinator.selectedIndexStats == nil)
    #expect(coordinator.selectedHost?.name == "Prod Cluster")

    // Selecting again, then reset clears everything
    coordinator.selectIndex("logs-2026", stats: stats)
    #expect(coordinator.screen == .indexDetail)
    coordinator.reset()
    #expect(coordinator.screen == .hostList)
    #expect(coordinator.selectedHost == nil)
    #expect(coordinator.selectedIndex == nil)
    #expect(coordinator.selectedIndexStats == nil)
  }
#endif

  @Test func testIndexAgeHelperDateMath() {
    #expect(IndexAgeHelper.dateMathExpression(value: 30, period: .Days) == "now-30d")
    #expect(IndexAgeHelper.dateMathExpression(value: 12, period: .Hours) == "now-12h")
    #expect(IndexAgeHelper.dateMathExpression(value: 5, period: .Minutes) == "now-5m")
    #expect(IndexAgeHelper.dateMathExpression(value: 2, period: .Weeks) == "now-2w")
    #expect(IndexAgeHelper.dateMathExpression(value: 6, period: .Months) == "now-6M")
    #expect(IndexAgeHelper.dateMathExpression(value: 1, period: .Years) == "now-1y")
    #expect(IndexAgeHelper.dateMathExpression(value: 45, period: .Seconds) == "now-45s")
  }

  @Test func testIndexAgeHelperApproximateCutoffDate() {
    let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
    let calendar = Calendar.current

    let cutoffDays = IndexAgeHelper.calculateCutoffDate(from: referenceDate, value: 10, period: .Days)
    let expectedDays = calendar.date(byAdding: .day, value: -10, to: referenceDate)!
    #expect(cutoffDays == expectedDays)

    let cutoffHours = IndexAgeHelper.calculateCutoffDate(from: referenceDate, value: 5, period: .Hours)
    let expectedHours = calendar.date(byAdding: .hour, value: -5, to: referenceDate)!
    #expect(cutoffHours == expectedHours)

    let cutoffWeeks = IndexAgeHelper.calculateCutoffDate(from: referenceDate, value: 2, period: .Weeks)
    let expectedWeeks = calendar.date(byAdding: .day, value: -14, to: referenceDate)!
    #expect(cutoffWeeks == expectedWeeks)

    let cutoffMonths = IndexAgeHelper.calculateCutoffDate(from: referenceDate, value: 3, period: .Months)
    let expectedMonths = calendar.date(byAdding: .month, value: -3, to: referenceDate)!
    #expect(cutoffMonths == expectedMonths)

    let cutoffYears = IndexAgeHelper.calculateCutoffDate(from: referenceDate, value: 1, period: .Years)
    let expectedYears = calendar.date(byAdding: .year, value: -1, to: referenceDate)!
    #expect(cutoffYears == expectedYears)
  }

  @Test func testIndexAgeHelperQueryBuilders() {
    let matchAll = IndexAgeHelper.buildMatchAllDeleteQuery()
    #expect(matchAll.contains("\"match_all\""))

    let rangeQuery = IndexAgeHelper.buildRangeDeleteQuery(dateField: "@timestamp", dateMathExpression: "now-30d")
    #expect(rangeQuery.contains("@timestamp"))
    #expect(rangeQuery.contains("now-30d"))
    #expect(rangeQuery.contains("lt"))
  }

  @Test func testDeleteByQuerySuccessResponseParsing() {
    let jsonString = """
    {
      "took": 128,
      "timed_out": false,
      "total": 4200,
      "deleted": 4200,
      "batches": 5,
      "version_conflicts": 0,
      "noops": 0,
      "failures": []
    }
    """
    let data = Data(jsonString.utf8)
    let result = IndexManagementService.parseDeleteResponse(data, httpStatus: 200)

    #expect(result.isSuccess)
    #expect(result.took == 128)
    #expect(result.timedOut == false)
    #expect(result.total == 4200)
    #expect(result.deleted == 4200)
    #expect(result.batches == 5)
    #expect(result.versionConflicts == 0)
    #expect(result.noops == 0)
    #expect(result.failures == [])
    #expect(result.errorMessage == nil)
  }

  @Test func testDeleteByQueryFailureResponseParsing() {
    let failureJson = """
    {
      "took": 45,
      "timed_out": false,
      "total": 10,
      "deleted": 2,
      "batches": 1,
      "version_conflicts": 8,
      "noops": 0,
      "failures": [
        {
          "index": "test-index",
          "type": "_doc",
          "id": "abc",
          "cause": {
            "type": "version_conflict_engine_exception",
            "reason": "[abc]: version conflict, required seqNo [1], primary term [1]"
          },
          "status": 409
        }
      ]
    }
    """
    let result1 = IndexManagementService.parseDeleteResponse(Data(failureJson.utf8), httpStatus: 200)
    #expect(!result1.isSuccess)
    #expect(result1.deleted == 2)
    #expect(result1.failures.count == 1)
    #expect(result1.errorMessage == "[abc]: version conflict, required seqNo [1], primary term [1]")

    let rootCauseJson = """
    {
      "error": {
        "root_cause": [
          {
            "type": "index_not_found_exception",
            "reason": "no such index [unknown-index]",
            "resource.type": "index_or_alias",
            "resource.id": "unknown-index",
            "index_uuid": "_na_",
            "index": "unknown-index"
          }
        ],
        "type": "index_not_found_exception",
        "reason": "no such index [unknown-index]"
      },
      "status": 404
    }
    """
    let result2 = IndexManagementService.parseDeleteResponse(Data(rootCauseJson.utf8), httpStatus: 404)
    #expect(!result2.isSuccess)
    #expect(result2.errorMessage == "no such index [unknown-index]")

    let networkError = ResponseError(title: "Request Error", message: "Connection refused", type: .critical)
    let result3 = IndexManagementService.parseDeleteResponse(nil, httpStatus: nil, requestError: networkError)
    #expect(!result3.isSuccess)
    #expect(result3.errorMessage == "Connection refused")
  }

  @Test func testParseTaskSubmission() {
    let started = IndexManagementService.parseTaskSubmission(Data(#"{"task":"oTUltX4IQMOUUVeiohTt8A:12345"}"#.utf8), httpStatus: 200)
    #expect(started == .started("oTUltX4IQMOUUVeiohTt8A:12345"))

    let notFound = """
    {"error":{"root_cause":[{"type":"index_not_found_exception","reason":"no such index [missing]"}],"type":"index_not_found_exception","reason":"no such index [missing]"},"status":404}
    """
    guard case .failed(let notFoundResult) = IndexManagementService.parseTaskSubmission(Data(notFound.utf8), httpStatus: 404) else {
      Issue.record("Expected failed submission"); return
    }
    #expect(!notFoundResult.isSuccess)
    #expect(notFoundResult.errorMessage == "no such index [missing]")

    let networkError = ResponseError(title: "Request Error", message: "Connection refused", type: .critical)
    guard case .failed(let networkResult) = IndexManagementService.parseTaskSubmission(nil, httpStatus: nil, requestError: networkError) else {
      Issue.record("Expected failed submission"); return
    }
    #expect(networkResult.errorMessage == "Connection refused")

    guard case .failed(let missingTaskResult) = IndexManagementService.parseTaskSubmission(Data("{}".utf8), httpStatus: 200) else {
      Issue.record("Expected failed submission"); return
    }
    #expect(!missingTaskResult.isSuccess)
    #expect(missingTaskResult.errorMessage != nil)
  }

  @Test func testParseTaskStatus_running() {
    let json = """
    {
      "completed": false,
      "task": {
        "node": "oTUltX4IQMOUUVeiohTt8A",
        "id": 12345,
        "action": "indices:data/write/delete/byquery",
        "status": { "total": 6154, "updated": 0, "created": 0, "deleted": 3500, "batches": 4, "version_conflicts": 0, "noops": 0 },
        "cancellable": true
      }
    }
    """
    guard case .running(let progress) = IndexManagementService.parseTaskStatus(Data(json.utf8), httpStatus: 200) else {
      Issue.record("Expected running status"); return
    }
    #expect(progress == DeleteTaskProgress(total: 6154, deleted: 3500, batches: 4))
  }

  @Test func testParseTaskStatus_completed() {
    let json = """
    {
      "completed": true,
      "task": { "node": "n1", "id": 1, "status": { "total": 4200, "deleted": 4200, "batches": 5 } },
      "response": { "took": 128, "timed_out": false, "total": 4200, "deleted": 4200, "batches": 5, "version_conflicts": 0, "noops": 0, "failures": [] }
    }
    """
    guard case .completed(let result) = IndexManagementService.parseTaskStatus(Data(json.utf8), httpStatus: 200) else {
      Issue.record("Expected completed status"); return
    }
    #expect(result.isSuccess)
    #expect(result.deleted == 4200)
    #expect(result.took == 128)
    #expect(result.canceled == nil)
    #expect(result.errorMessage == nil)
  }

  @Test func testParseTaskStatus_cancelled() {
    let json = """
    {
      "completed": true,
      "task": { "node": "n1", "id": 1, "cancelled": true },
      "response": { "took": 900, "timed_out": false, "total": 6154, "deleted": 3500, "batches": 4, "failures": [], "canceled": "by user request" }
    }
    """
    guard case .completed(let result) = IndexManagementService.parseTaskStatus(Data(json.utf8), httpStatus: 200) else {
      Issue.record("Expected completed status"); return
    }
    #expect(!result.isSuccess)
    #expect(result.canceled == "by user request")
    #expect(result.errorMessage == "Cancelled after deleting 3500 of 6154")
  }

  @Test func testParseTaskStatus_completedWithError() {
    let json = """
    {
      "completed": true,
      "task": { "node": "n1", "id": 1 },
      "error": { "type": "search_phase_execution_exception", "reason": "all shards failed" }
    }
    """
    guard case .completed(let result) = IndexManagementService.parseTaskStatus(Data(json.utf8), httpStatus: 200) else {
      Issue.record("Expected completed status"); return
    }
    #expect(!result.isSuccess)
    #expect(result.errorMessage == "all shards failed")
  }

  @Test func testParseTaskStatus_untrackableAndPollFailures() {
    let notFound = """
    {"error":{"root_cause":[{"type":"resource_not_found_exception","reason":"task [n1:1] isn't running and hasn't stored its results"}],"type":"resource_not_found_exception","reason":"task [n1:1] isn't running and hasn't stored its results"},"status":404}
    """
    guard case .untrackable(let err404) = IndexManagementService.parseTaskStatus(Data(notFound.utf8), httpStatus: 404) else {
      Issue.record("Expected untrackable for 404"); return
    }
    #expect(err404.message == "task [n1:1] isn't running and hasn't stored its results")

    guard case .untrackable = IndexManagementService.parseTaskStatus(nil, httpStatus: 403) else {
      Issue.record("Expected untrackable for 403"); return
    }

    guard case .pollFailed = IndexManagementService.parseTaskStatus(nil, httpStatus: 502) else {
      Issue.record("Expected pollFailed for 502"); return
    }

    let networkError = ResponseError(title: "Request Error", message: "Connection refused", type: .critical)
    guard case .pollFailed(let netErr) = IndexManagementService.parseTaskStatus(nil, httpStatus: nil, requestError: networkError) else {
      Issue.record("Expected pollFailed for network error"); return
    }
    #expect(netErr.message == "Connection refused")
  }

  @Test func testDateFieldRanking() {
    let field1 = DateFieldInfo(name: "created_at", isNanos: false, isSeconds: false)
    let field2 = DateFieldInfo(name: "@timestamp", isNanos: false, isSeconds: false)
    let field3 = DateFieldInfo(name: "timestamp", isNanos: false, isSeconds: false)
    let field4 = DateFieldInfo(name: "meta.updated_at", isNanos: false, isSeconds: false)

    let best = IndexActivityService.selectBestDateField(from: [field1, field4, field2, field3])
    #expect(best?.name == "@timestamp")

    let bestWithoutAtTimestamp = IndexActivityService.selectBestDateField(from: [field1, field4, field3])
    #expect(bestWithoutAtTimestamp?.name == "timestamp")
  }

  @Test func testIndexAgeHelper_zeroAndNegativeBoundary() {
    #expect(IndexAgeHelper.dateMathExpression(value: 0, period: .Days) == "now-1d")
    #expect(IndexAgeHelper.dateMathExpression(value: -10, period: .Hours) == "now-1h")

    let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
    let calendar = Calendar.current
    let cutoffZero = IndexAgeHelper.calculateCutoffDate(from: referenceDate, value: 0, period: .Days)
    let expectedOneDayAgo = calendar.date(byAdding: .day, value: -1, to: referenceDate)!
    #expect(cutoffZero == expectedOneDayAgo)

    let cutoffNegative = IndexAgeHelper.calculateCutoffDate(from: referenceDate, value: -5, period: .Weeks)
    let expectedOneWeekAgo = calendar.date(byAdding: .day, value: -7, to: referenceDate)!
    #expect(cutoffNegative == expectedOneWeekAgo)
  }

  @Test func testParseErrorMessage_htmlAndHttpErrorHandling() {
    let htmlData = Data("<html><head><title>502 Bad Gateway</title></head><body>502 Bad Gateway</body></html>".utf8)
    let err502 = IndexManagementService.parseErrorMessage(from: htmlData, httpStatus: 502)
    #expect(err502 != nil)
    #expect(err502?.title == "HTTP Error 502")
    #expect(err502?.message == "Server returned HTTP 502")

    let err500 = IndexManagementService.parseErrorMessage(from: nil, httpStatus: 500)
    #expect(err500 != nil)
    #expect(err500?.title == "HTTP Error 500")
    #expect(err500?.message == "Request failed with HTTP status 500")

    let plainData = Data("Service Unavailable".utf8)
    let err503 = IndexManagementService.parseErrorMessage(from: plainData, httpStatus: 503)
    #expect(err503 != nil)
    #expect(err503?.message == "Service Unavailable")

    let deleteResult502 = IndexManagementService.parseDeleteResponse(htmlData, httpStatus: 502)
    #expect(!deleteResult502.isSuccess)
    #expect(deleteResult502.errorMessage == "Server returned HTTP 502")

    let deleteResult500 = IndexManagementService.parseDeleteResponse(nil, httpStatus: 500)
    #expect(!deleteResult500.isSuccess)
    #expect(deleteResult500.errorMessage == "Request failed with HTTP status 500")
  }

  @Test func testExtractIndexStats_aliasAndConcreteResolution() {
    let stats: [String: IndexStatsItem] = [
      "logs-2026-01": IndexStatsItem(docCount: 100, storageBytes: 1000, totalDocCount: 200, totalStorageBytes: 2000, deletedDocCount: 5),
      "logs-2026-02": IndexStatsItem(docCount: 300, storageBytes: 3000, totalDocCount: 600, totalStorageBytes: 6000, deletedDocCount: 15)
    ]

    let exact = IndexManagementService.extractIndexStats(from: stats, for: "logs-2026-01")
    #expect(exact?.docCount == 100)
    #expect(exact?.storageBytes == 1000)

    let aliasMulti = IndexManagementService.extractIndexStats(from: stats, for: "logs-alias")
    #expect(aliasMulti?.docCount == 400)
    #expect(aliasMulti?.storageBytes == 4000)
    #expect(aliasMulti?.totalDocCount == 800)
    #expect(aliasMulti?.totalStorageBytes == 8000)
    #expect(aliasMulti?.deletedDocCount == 20)

    let singleMap = ["backing-idx": IndexStatsItem(docCount: 50, storageBytes: 500)]
    let aliasSingle = IndexManagementService.extractIndexStats(from: singleMap, for: "my-alias")
    #expect(aliasSingle?.docCount == 50)
    #expect(aliasSingle?.storageBytes == 500)

    let empty = IndexManagementService.extractIndexStats(from: [:], for: "any")
    #expect(empty == nil)
  }

  @Test func testValidateTargetIndex_rejectsUnsafeTargets() {
    let rejected = [
      "", " ", "\t",
      ".", "..",
      "_all", "_ALL",
      "*", "logs-*", "logs-?", "a,b",
      "-logs", "+logs", "_logs",
      "a/b", "a\\b", "a\"b", "<logs-{now/d}>", "a|b", "a#b", "remote:logs",
      "logs 2026", "logs\n",
      "%5Fall", "logs%2A", "a%2Cb", "%2E%2E"
    ]
    for name in rejected {
      #expect(IndexManagementService.validateTargetIndex(name) != nil, "Expected '\(name)' to be rejected")
    }

    #expect(IndexManagementService.validateTargetIndex("_all")?.message == "Deleting from '_all' indices is not allowed")
    #expect(IndexManagementService.validateTargetIndex("")?.message == "Index name is empty")
  }

  @Test func testValidateTargetIndex_acceptsConcreteTargets() {
    let accepted = [
      "logs",
      "logs-2026.09.24",
      "my_index-01",
      ".kibana_1",
      ".security-7",
      ".ds-logs-app-2026.09.24-000001",
      "logs-alias"
    ]
    for name in accepted {
      #expect(IndexManagementService.validateTargetIndex(name) == nil, "Expected '\(name)' to be accepted")
    }
  }

  @Test @MainActor func testDeleteFunctions_rejectInvalidTargetBeforeRequest() async {
    let host = HostDetails()
    let expected = IndexManagementService.validateTargetIndex("logs-*")?.message

    let allSubmission = await IndexManagementService.deleteAllDocuments(serverDetails: host, index: "logs-*")
    #expect(allSubmission == .failed(DeleteByQueryResult(errorMessage: expected, isSuccess: false)))

    let ageSubmission = await IndexManagementService.deleteDocumentsByAge(
      serverDetails: host,
      index: "_all",
      dateField: "@timestamp",
      dateMathExpression: "now-30d"
    )
    #expect(ageSubmission == .failed(DeleteByQueryResult(errorMessage: "Deleting from '_all' indices is not allowed", isSuccess: false)))
  }
  @Test @MainActor func testDeleteFunctions_blockedInReadOnlyMode() async {
    // A valid target with no host: had it been sent, the error would be about the request instead
    let host = HostDetails()
    let expected = DeleteTaskSubmission.failed(DeleteByQueryResult(errorMessage: IndexManagementService.readOnlyMessage,
                                                                   isSuccess: false))

    let allSubmission = await IndexManagementService.deleteAllDocuments(serverDetails: host, index: "logs", readOnly: true)
    #expect(allSubmission == expected)

    let ageSubmission = await IndexManagementService.deleteDocumentsByAge(
      serverDetails: host,
      index: "logs",
      dateField: "@timestamp",
      dateMathExpression: "now-30d",
      readOnly: true
    )
    #expect(ageSubmission == expected)

    let notReadOnly = await IndexManagementService.deleteAllDocuments(serverDetails: host, index: "logs", readOnly: false)
    #expect(notReadOnly != expected)
  }


  // MARK: - IndexDeleteTaskTracker

  @MainActor
  private func makeDeleteTracker(
    _ cluster: ScriptedDeleteTaskCluster,
    cancel: @escaping IndexDeleteTaskTracker.Canceller = { _, _ in nil }
  ) -> IndexDeleteTaskTracker {
    IndexDeleteTaskTracker(
      fetchStatus: { _, _ in cluster.nextStatus() },
      cancelTask: cancel,
      sleep: { interval in await cluster.didSleep(interval) },
      initialPollInterval: 1,
      maxPollInterval: 3,
      maxPollFailures: 3
    )
  }

  @MainActor
  private func makeTrackerHost() -> HostDetails {
    let host = HostDetails()
    host.id = UUID()
    host.name = "Tracker Cluster"
    return host
  }

  @Test @MainActor func testDeleteTracker_runningThenCompleted() async {
    let completed = DeleteByQueryResult(took: 128, total: 4200, deleted: 4200, batches: 5, failures: [], isSuccess: true)
    let cluster = ScriptedDeleteTaskCluster([
      .running(DeleteTaskProgress(total: 4200, deleted: 1000, batches: 1)),
      .running(DeleteTaskProgress(total: 4200, deleted: 2000, batches: 2)),
      .running(DeleteTaskProgress(total: 4200, deleted: 3000, batches: 3)),
      .completed(completed)
    ])
    var observedStates: [DeleteOperationState] = []
    let tracker = makeDeleteTracker(cluster)
    let host = makeTrackerHost()
    let key = IndexDeleteTaskTracker.key(host: host, index: "logs")
    cluster.onSleep = { observedStates.append(tracker.operations[key]!.state) }

    #expect(tracker.start(kind: .byAge, host: host, index: "logs") { _ in .started("n1:1") })
    #expect(tracker.operations[key]?.state == .submitting)
    #expect(tracker.operations[key]?.kind == .byAge)

    await tracker.waitUntilSettled(key)

    #expect(tracker.operations[key]?.state == .finished(completed))
    #expect(tracker.completions[key] == 1)
    #expect(cluster.fetchCount == 4)
    // Interval grows by the initial step each poll and is capped at the max
    #expect(cluster.sleeps == [1, 2, 3, 3])
    #expect(observedStates.first == .running(taskId: "n1:1", progress: nil))
    #expect(observedStates.last == .running(taskId: "n1:1", progress: DeleteTaskProgress(total: 4200, deleted: 3000, batches: 3)))
  }

  @Test @MainActor func testDeleteTracker_threeConsecutivePollErrorsBecomeUntracked() async {
    let failure = DeleteTaskStatus.pollFailed(ResponseError(title: "Request Error", message: "Request timed out", type: .critical))
    let cluster = ScriptedDeleteTaskCluster([
      failure,
      .running(DeleteTaskProgress(total: 10, deleted: 5)),
      failure,
      failure,
      failure
    ])
    let tracker = makeDeleteTracker(cluster)
    let host = makeTrackerHost()
    let key = IndexDeleteTaskTracker.key(host: host, index: "logs")

    tracker.start(kind: .all, host: host, index: "logs") { _ in .started("n1:2") }
    await tracker.waitUntilSettled(key)

    // The running poll in between resets the failure count, so 5 polls are needed
    #expect(cluster.fetchCount == 5)
    guard case .untracked(let taskId, let message) = tracker.operations[key]?.state else {
      Issue.record("Expected untracked state"); return
    }
    #expect(taskId == "n1:2")
    #expect(message.contains("Task n1:2 may still be running on the cluster"))
    #expect(message.contains("Request timed out"))
    #expect(!(tracker.isActive(key)))
    #expect(tracker.completions[key] == 1)
  }

  @Test @MainActor func testDeleteTracker_forbiddenTasksApiBecomesUntrackedImmediately() async {
    let forbidden = ResponseError(title: "security_exception", message: "action [cluster:monitor/task/get] is unauthorized", type: .warn)
    let cluster = ScriptedDeleteTaskCluster([.untrackable(forbidden)])
    let tracker = makeDeleteTracker(cluster)
    let host = makeTrackerHost()
    let key = IndexDeleteTaskTracker.key(host: host, index: "logs")

    tracker.start(kind: .all, host: host, index: "logs") { _ in .started("n1:3") }
    await tracker.waitUntilSettled(key)

    #expect(cluster.fetchCount == 1)
    guard case .untracked(_, let message) = tracker.operations[key]?.state else {
      Issue.record("Expected untracked state"); return
    }
    #expect(message.contains("may still be running"))
    #expect(message.contains("unauthorized"))
  }

  @Test @MainActor func testDeleteTracker_secondStartOnSameIndexIsRefused() async {
    let done = DeleteByQueryResult(deleted: 1, failures: [], isSuccess: true)
    let cluster = ScriptedDeleteTaskCluster([.completed(done), .completed(done), .completed(done)])
    let tracker = makeDeleteTracker(cluster)
    let host = makeTrackerHost()
    let key = IndexDeleteTaskTracker.key(host: host, index: "logs")
    var submitCount = 0

    #expect(tracker.start(kind: .all, host: host, index: "logs") { _ in submitCount += 1; return .started("n1:4") })
    #expect(!(tracker.start(kind: .byAge, host: host, index: "logs") { _ in submitCount += 1; return .started("n1:5") }))
    #expect(tracker.operations[key]?.kind == .all)

    // A different index on the same host is independent
    let otherKey = IndexDeleteTaskTracker.key(host: host, index: "metrics")
    #expect(tracker.start(kind: .all, host: host, index: "metrics") { _ in submitCount += 1; return .started("n1:6") })

    await tracker.waitUntilSettled(key)
    await tracker.waitUntilSettled(otherKey)
    #expect(submitCount == 2)

    // Once finished, a new delete may start
    #expect(tracker.start(kind: .byAge, host: host, index: "logs") { _ in .started("n1:7") })
    await tracker.waitUntilSettled(key)
    #expect(tracker.completions[key] == 2)
  }

  @Test @MainActor func testDeleteTracker_failedSubmissionFinishesWithoutPolling() async {
    let cluster = ScriptedDeleteTaskCluster([])
    let tracker = makeDeleteTracker(cluster)
    let host = makeTrackerHost()
    let key = IndexDeleteTaskTracker.key(host: host, index: "logs")
    let rejected = DeleteByQueryResult(errorMessage: "no such index [logs]", isSuccess: false)

    tracker.start(kind: .all, host: host, index: "logs") { _ in .failed(rejected) }
    await tracker.waitUntilSettled(key)

    #expect(tracker.operations[key]?.state == .finished(rejected))
    #expect(cluster.fetchCount == 0)

    tracker.clear(key)
    #expect(tracker.operations[key] == nil)
  }

  @Test @MainActor func testDeleteTracker_cancelMovesToCancellingAndRevertsWhenRejected() async {
    let cancelled = DeleteByQueryResult(total: 10, deleted: 4, failures: [], canceled: "by user request", errorMessage: "Cancelled after deleting 4 of 10", isSuccess: false)
    let cluster = ScriptedDeleteTaskCluster([
      .running(DeleteTaskProgress(total: 10, deleted: 2)),
      .running(DeleteTaskProgress(total: 10, deleted: 3)),
      .running(DeleteTaskProgress(total: 10, deleted: 4)),
      .completed(cancelled)
    ])
    var cancelCalls = 0
    let tracker = makeDeleteTracker(cluster, cancel: { _, _ in
      cancelCalls += 1
      return cancelCalls == 1 ? ResponseError(title: "Cancel Failed", message: "task not cancellable", type: .warn) : nil
    })
    let host = makeTrackerHost()
    let key = IndexDeleteTaskTracker.key(host: host, index: "logs")
    var statesAfterCancel: [DeleteOperationState] = []
    var notices: [String?] = []

    cluster.onSleep = {
      switch cluster.sleeps.count {
      case 2, 4:
        tracker.cancel(key)
        if case .cancelling = tracker.operations[key]?.state {
          statesAfterCancel.append(tracker.operations[key]!.state)
        }
      case 3:
        // Let the rejected cancel request land before the next poll
        for _ in 0..<10 { await Task.yield() }
        notices.append(tracker.operations[key]?.notice)
      default:
        break
      }
    }

    tracker.start(kind: .all, host: host, index: "logs") { _ in .started("n1:8") }
    await tracker.waitUntilSettled(key)
    // The second cancel request is fire-and-forget, let it run
    for _ in 0..<10 { await Task.yield() }

    #expect(cancelCalls == 2)
    #expect(statesAfterCancel.count == 2)
    #expect(notices == ["Cancel failed: task not cancellable"])
    #expect(tracker.operations[key]?.state == .finished(cancelled))
    #expect(tracker.operations[key]?.notice == nil)
  }

  // MARK: - IndexManagementPreferences

  @Test func testIndexReadOnlyDefaultsToOnUntilChanged() throws {
    let suiteName = "IndexManagementPreferencesTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    // Nothing stored yet, which is how existing users start after upgrading
    #expect(IndexManagementPreferences.isReadOnly(defaults))

    defaults.set(false, forKey: IndexManagementPreferences.readOnlyKey)
    #expect(!IndexManagementPreferences.isReadOnly(defaults))

    defaults.set(true, forKey: IndexManagementPreferences.readOnlyKey)
    #expect(IndexManagementPreferences.isReadOnly(defaults))
  }
}

/// Plays back a fixed sequence of `_tasks` responses for IndexDeleteTaskTracker tests
@MainActor
private final class ScriptedDeleteTaskCluster {
  private var statuses: [DeleteTaskStatus]
  private(set) var fetchCount = 0
  private(set) var sleeps: [UInt64] = []
  var onSleep: (() async -> Void)?

  init(_ statuses: [DeleteTaskStatus]) {
    self.statuses = statuses
  }

  func nextStatus() -> DeleteTaskStatus {
    fetchCount += 1
    guard !statuses.isEmpty else {
      return .pollFailed(ResponseError(title: "Script", message: "No scripted status left", type: .warn))
    }
    return statuses.removeFirst()
  }

  func didSleep(_ interval: UInt64) async {
    sleeps.append(interval)
    await onSleep?()
  }
}
