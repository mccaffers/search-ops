// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

@available(iOS 16.0.0, *)
final class DevConsoleTemplatesTests: XCTestCase {

  // A typical dynamically mapped log index
  private let logsMapping = """
  {
    "logs-2025.10.04": {
      "mappings": {
        "properties": {
          "@timestamp": { "type": "date" },
          "event": { "properties": { "created": { "type": "date" } } },
          "message": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 } } },
          "request_id": { "type": "keyword" },
          "level": { "type": "keyword" },
          "http": { "properties": { "response": { "properties": { "bytes": { "type": "long" } } } } },
          "duration_ms": { "type": "float" },
          "tags": { "type": "nested", "properties": { "name": { "type": "keyword" } } }
        }
      }
    }
  }
  """

  private func fieldNames(_ fields: [TemplateField]) -> [String] {
    fields.map(\.name)
  }

  private func parse(_ template: String) throws -> (DevConsoleRequest, [String: Any]) {
    let request = try DevConsoleParser.parse(template).get()
    let body = try XCTUnwrap(request.body, "Template has no body")
    let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])
    return (request, json)
  }

  // MARK: Catalog

  func testCatalogFlattensObjectsAndIncludesMultiFields() {
    let names = fieldNames(TemplateFieldCatalog.parse(logsMapping))
    XCTAssertTrue(names.contains("message"))
    XCTAssertTrue(names.contains("message.keyword"))
    XCTAssertTrue(names.contains("event.created"))
    XCTAssertTrue(names.contains("http.response.bytes"))
    // Nested fields need a nested query, only the nested field itself is listed
    XCTAssertTrue(names.contains("tags"))
    XCTAssertFalse(names.contains("tags.name"))
  }

  func testCatalogReadsElasticsearch6MappingTypes() {
    let mapping = """
    {"old-index": {"mappings": {"_doc": {"properties": {
      "timestamp": {"type": "date"}, "status": {"type": "keyword"}
    }}}}}
    """
    XCTAssertEqual(fieldNames(TemplateFieldCatalog.parse(mapping)), ["status", "timestamp"])
  }

  func testCatalogMergesFieldsAcrossIndices() {
    let mapping = """
    {
      "logs-a": {"mappings": {"properties": {"@timestamp": {"type": "date"}, "level": {"type": "keyword"}}}},
      "logs-b": {"mappings": {"properties": {"@timestamp": {"type": "date"}, "bytes": {"type": "long"}}}}
    }
    """
    XCTAssertEqual(fieldNames(TemplateFieldCatalog.parse(mapping)), ["@timestamp", "bytes", "level"])
  }

  func testCatalogIgnoresErrorsAndInvalidJSON() {
    XCTAssertTrue(TemplateFieldCatalog.parse("not json").isEmpty)
    XCTAssertTrue(TemplateFieldCatalog.parse(#"{"error": {"reason": "no such index"}, "status": 404}"#).isEmpty)
  }

  // MARK: Suggestions

  func testSuggestionsPreferCommonFieldsAndAvoidIdentifiers() {
    let suggested = TemplateFieldSuggester.suggestAll(in: TemplateFieldCatalog.parse(logsMapping))
    XCTAssertEqual(suggested[.date]?.name, "@timestamp")
    XCTAssertEqual(suggested[.keyword]?.name, "level")
    XCTAssertEqual(suggested[.text]?.name, "message")
    XCTAssertEqual(suggested[.numeric]?.name, "duration_ms")
  }

  func testKeywordSuggestionFallsBackToMultiField() {
    let mapping = """
    {"idx": {"mappings": {"properties": {
      "user_id": {"type": "keyword"},
      "service": {"type": "text", "fields": {"keyword": {"type": "keyword"}}}
    }}}}
    """
    let suggested = TemplateFieldSuggester.suggest(.keyword, in: TemplateFieldCatalog.parse(mapping))
    XCTAssertEqual(suggested?.name, "service.keyword")
  }

  func testCamelCaseIdentifiersAreAvoided() {
    let fields = [TemplateField(name: "orderId", type: "keyword"),
                  TemplateField(name: "region", type: "keyword")]
    XCTAssertEqual(TemplateFieldSuggester.suggest(.keyword, in: fields)?.name, "region")
  }

  // MARK: Templates

  func testEveryTemplateParsesAsAValidRequest() throws {
    let fields = TemplateFieldSuggester.suggestAll(in: TemplateFieldCatalog.parse(logsMapping))
    for template in DevConsoleTemplate.allCases {
      let text = try XCTUnwrap(template.render(index: "logs-*", fields: fields), template.title)
      let (request, _) = try parse(text)
      XCTAssertEqual(request.method, .GET, template.title)
      XCTAssertTrue(request.path.hasPrefix("/logs-*/"), template.title)
    }
  }

  func testSearchTemplate() throws {
    let fields = TemplateFieldSuggester.suggestAll(in: TemplateFieldCatalog.parse(logsMapping))
    let (request, json) = try parse(try XCTUnwrap(DevConsoleTemplate.search.render(index: "logs-*", fields: fields)))
    XCTAssertEqual(request.path, "/logs-*/_search")
    XCTAssertEqual(json["size"] as? Int, 20)
    let sort = try XCTUnwrap(json["sort"] as? [[String: String]])
    XCTAssertEqual(sort.first?["@timestamp"], "desc")
    let bool = try XCTUnwrap((json["query"] as? [String: Any])?["bool"] as? [String: Any])
    XCTAssertNotNil(bool["must"])
    XCTAssertNotNil(bool["filter"])
  }

  func testSearchAndCountFallBackToMatchAllWithoutFields() throws {
    let (_, search) = try parse(try XCTUnwrap(DevConsoleTemplate.search.render(index: "idx", fields: [:])))
    XCTAssertNotNil((search["query"] as? [String: Any])?["match_all"])
    XCTAssertNil(search["sort"])

    let (count, json) = try parse(try XCTUnwrap(DevConsoleTemplate.count.render(index: "idx", fields: [:])))
    XCTAssertEqual(count.path, "/idx/_count")
    XCTAssertNotNil((json["query"] as? [String: Any])?["match_all"])
  }

  func testTermsTemplateUsesTheChosenKeywordField() throws {
    let fields: [TemplateFieldRole: TemplateField] = [.keyword: TemplateField(name: "message.keyword", type: "keyword")]
    let (_, json) = try parse(try XCTUnwrap(DevConsoleTemplate.termsAggregation.render(index: "idx", fields: fields)))
    XCTAssertEqual(json["size"] as? Int, 0)
    XCTAssertNil(json["query"])
    let aggs = try XCTUnwrap(json["aggs"] as? [String: Any])
    let terms = try XCTUnwrap((aggs["top_values"] as? [String: Any])?["terms"] as? [String: Any])
    XCTAssertEqual(terms["field"] as? String, "message.keyword")
  }

  func testTemplatesNeedTheirRequiredFields() {
    let onlyText: [TemplateFieldRole: TemplateField] = [.text: TemplateField(name: "message", type: "text")]
    XCTAssertNil(DevConsoleTemplate.termsAggregation.render(index: "idx", fields: onlyText))
    XCTAssertNil(DevConsoleTemplate.dateHistogram.render(index: "idx", fields: onlyText))
    XCTAssertNil(DevConsoleTemplate.fieldStats.render(index: "idx", fields: onlyText))
    XCTAssertEqual(DevConsoleTemplate.fieldStats.unavailableReason(fields: onlyText), "No numeric fields in the mapping")
    XCTAssertNil(DevConsoleTemplate.search.unavailableReason(fields: onlyText))
  }

  func testDateHistogramIntervalFollowsTheHostVersion() throws {
    let fields: [TemplateFieldRole: TemplateField] = [.date: TemplateField(name: "@timestamp", type: "date")]

    func histogram(_ version: String) throws -> [String: Any] {
      let (_, json) = try parse(try XCTUnwrap(DevConsoleTemplate.dateHistogram.render(index: "idx", fields: fields, version: version)))
      let aggs = try XCTUnwrap(json["aggs"] as? [String: Any])
      return try XCTUnwrap((aggs["over_time"] as? [String: Any])?["date_histogram"] as? [String: Any])
    }

    XCTAssertEqual(try histogram("")["fixed_interval"] as? String, "1h")
    XCTAssertEqual(try histogram("8.15.0")["fixed_interval"] as? String, "1h")
    XCTAssertEqual(try histogram("2.11.0")["fixed_interval"] as? String, "1h") // OpenSearch
    XCTAssertEqual(try histogram("6.8.23")["interval"] as? String, "1h")
    XCTAssertEqual(try histogram("7.1.1")["interval"] as? String, "1h")
    XCTAssertNil(try histogram("6.8.23")["fixed_interval"])
  }

  func testTimeRangeSetsTheDateFilterAndHistogramInterval() throws {
    let fields: [TemplateFieldRole: TemplateField] = [.date: TemplateField(name: "@timestamp", type: "date")]

    func gte(_ json: [String: Any]) -> String? {
      let range = (json["query"] as? [String: Any])?["range"] as? [String: Any]
      return (range?["@timestamp"] as? [String: Any])?["gte"] as? String
    }

    let (_, defaultCount) = try parse(try XCTUnwrap(DevConsoleTemplate.count.render(index: "idx", fields: fields)))
    XCTAssertEqual(gte(defaultCount), "now-24h")

    let (_, weekCount) = try parse(try XCTUnwrap(DevConsoleTemplate.count.render(index: "idx", fields: fields, range: .last7Days)))
    XCTAssertEqual(gte(weekCount), "now-7d")

    let (_, histogram) = try parse(try XCTUnwrap(DevConsoleTemplate.dateHistogram.render(index: "idx", fields: fields, version: "8.15.0", range: .last30Days)))
    XCTAssertEqual(gte(histogram), "now-30d")
    let aggs = try XCTUnwrap(histogram["aggs"] as? [String: Any])
    let dateHistogram = try XCTUnwrap((aggs["over_time"] as? [String: Any])?["date_histogram"] as? [String: Any])
    XCTAssertEqual(dateHistogram["fixed_interval"] as? String, "1d")

    let (_, longHistogram) = try parse(try XCTUnwrap(DevConsoleTemplate.dateHistogram.render(index: "idx", fields: fields, version: "6.8.23", range: .last5Years)))
    XCTAssertEqual(gte(longHistogram), "now-5y")
    let longAggs = try XCTUnwrap(longHistogram["aggs"] as? [String: Any])
    let longDateHistogram = try XCTUnwrap((longAggs["over_time"] as? [String: Any])?["date_histogram"] as? [String: Any])
    XCTAssertEqual(longDateHistogram["interval"] as? String, "30d")

    XCTAssertEqual(TemplateTimeRange.last6Months.dateMath, "now-6M")
    XCTAssertEqual(DevConsoleTemplate.dateHistogram.summary(range: .lastYear), "Documents per week over the last year")
    XCTAssertEqual(DevConsoleTemplate.count.summary(range: .lastHour), "Number of documents from the last hour")
    XCTAssertEqual(DevConsoleTemplate.dateHistogram.summary, "Documents per hour over the last 24 hours")
  }

  func testFieldStatsTemplate() throws {
    let fields: [TemplateFieldRole: TemplateField] = [.numeric: TemplateField(name: "http.response.bytes", type: "long")]
    let text = try XCTUnwrap(DevConsoleTemplate.fieldStats.render(index: "idx", fields: fields))
    XCTAssertTrue(text.contains(#""percents": [50, 95, 99]"#))
    let (_, json) = try parse(text)
    let aggs = try XCTUnwrap(json["aggs"] as? [String: Any])
    XCTAssertEqual(((aggs["stats"] as? [String: Any])?["stats"] as? [String: Any])?["field"] as? String,
                   "http.response.bytes")
  }

  func testRenderedJSONIsIndented() throws {
    let text = try XCTUnwrap(DevConsoleTemplate.count.render(index: "idx", fields: [:]))
    XCTAssertEqual(text, """
    GET /idx/_count
    {
      "query": {
        "match_all": {}
      }
    }
    """)
  }

  func testFieldNamesAreEscaped() throws {
    let fields: [TemplateFieldRole: TemplateField] = [.keyword: TemplateField(name: #"odd"name"#, type: "keyword")]
    let (_, json) = try parse(try XCTUnwrap(DevConsoleTemplate.termsAggregation.render(index: "idx", fields: fields)))
    let aggs = try XCTUnwrap(json["aggs"] as? [String: Any])
    XCTAssertEqual(((aggs["top_values"] as? [String: Any])?["terms"] as? [String: Any])?["field"] as? String, #"odd"name"#)
  }

  // MARK: Index from the editor

  func testIndexIsReadFromTheEditorPath() {
    XCTAssertEqual(DevConsoleTemplate.index(fromRequestText: "GET /logs-*/_search\n{}"), "logs-*")
    XCTAssertEqual(DevConsoleTemplate.index(fromRequestText: "GET orders/_count?pretty"), "orders")
    XCTAssertNil(DevConsoleTemplate.index(fromRequestText: "GET /_cat/indices"))
    XCTAssertNil(DevConsoleTemplate.index(fromRequestText: "GET /"))
    XCTAssertNil(DevConsoleTemplate.index(fromRequestText: "nonsense"))
  }

  func testEmptyIndexTargetsAllIndices() throws {
    let text = try XCTUnwrap(DevConsoleTemplate.count.render(index: " ", fields: [:]))
    XCTAssertTrue(text.hasPrefix("GET /_all/_count"))
  }
}
