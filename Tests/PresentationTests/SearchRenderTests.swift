// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import Combine
import RealmSwift
import OrderedCollections

@testable import Search_Ops

final class SearchRenderTests: XCTestCase  {
  
  var searchRender: SearchRender!
  var filterObject: FilterObject!
  var queryObject: QueryObject!
  var squasedFieldsArray: SquashedFieldsArray!
  var relativeRangeFilter: RelativeRangeFilter!
  var sortObject: SortObject!
  var hostDetails: HostDetails!
  var limitObj: LimitObj!
  
  override func setUp() {
    super.setUp()
    
    // Initialize dependencies
    queryObject = QueryObject()
    queryObject.compound = .must  // or .should, as per test case needs
    queryObject.values.append(objectsIn: [
      QueryFilterObject(string: "filter1"),
      QueryFilterObject(string: "filter2")
    ])
    
    squasedFieldsArray = SquashedFieldsArray(squashedString: "exampleField")
    squasedFieldsArray.fieldParts = ["part1", "part2"]
    squasedFieldsArray.type = "text"
    squasedFieldsArray.index = "mainIndex"
    squasedFieldsArray.visible = true
    
    relativeRangeFilter = RelativeRangeFilter(period: .Hours, value: 2.0) // Set to 2 hours for testing
    
    // Initialize SortObject with the squasedFieldsArray
    sortObject = SortObject(order: SortOrderEnum.Ascending, field: squasedFieldsArray)
    
    // Initialize FilterObject with all properties including the SortObject
    filterObject = FilterObject(
      query: queryObject,
      dateField: squasedFieldsArray,
      relativeRange: relativeRangeFilter,
      absoluteRange: nil,  // Adjust with actual parameters
      sort: sortObject  // Use the initialized SortObject
    )
    
    hostDetails = HostDetails()
    hostDetails.host = HostURL()
    hostDetails.host?.url = "example.com"
    hostDetails.host?.port = "8080"
    limitObj = LimitObj(size: 10)
    
    // Initialize the class to be tested
    searchRender = SearchRender()
  }
  
  func testCallWithValidInput() async throws {
    // Arrange
    var result: RenderResult?
    
    // Act
    result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails, index: "testIndex", limitObj: limitObj)
    
    // Assert
    XCTAssertNotNil(result, "Result should not be nil")
    // Add more specific assertions here based on the properties of RenderResult
  }

  func testCallWithQueryShardException() async throws {
    let mockResponse = """
    {
      "error": {
        "root_cause": [
          {
            "type": "query_shard_exception",
            "reason": "Failed to parse query [test]"
          }
        ]
      },
      "status": 400
    }
    """
    Request.mockedSession = MockURLSession(response: mockResponse)
    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails, index: "testIndex", limitObj: limitObj)
    
    XCTAssertNotNil(result.error)
    XCTAssertEqual(result.error?.title, "query_shard_exception")
    XCTAssertEqual(result.error?.message, "Failed to parse query [test]")
    XCTAssertNotNil(result.duration, "A failed search still reports its round-trip time")
  }

  func testCallReportsDurationOnSuccess() async throws {
    let mockResponse = """
    {
      "took": 3,
      "hits": {
        "total": { "value": 1, "relation": "eq" },
        "hits": [ { "_id": "1", "_source": { "message": "hello" } } ]
      }
    }
    """
    Request.mockedSession = MockURLSession(response: mockResponse)
    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails, index: "testIndex", limitObj: limitObj)

    XCTAssertNil(result.error)
    XCTAssertNotNil(result.duration)
  }

  func testCallWithParsingException() async throws {
    let mockResponse = """
    {
      "error": {
        "root_cause": [
          {
            "type": "parsing_exception",
            "reason": "Unknown query type"
          }
        ]
      },
      "status": 400
    }
    """
    Request.mockedSession = MockURLSession(response: mockResponse)
    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails, index: "testIndex", limitObj: limitObj)
    
    XCTAssertNotNil(result.error)
    XCTAssertEqual(result.error?.title, "parsing_exception")
    XCTAssertEqual(result.error?.message, "Unknown query type")
  }

  func testCallWithUnknownExceptionFallback() async throws {
    let mockResponse = """
    {
      "error": {
        "reason": "Something broke"
      },
      "status": 500
    }
    """
    Request.mockedSession = MockURLSession(response: mockResponse)
    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails, index: "testIndex", limitObj: limitObj)
    
    XCTAssertNotNil(result.error)
    XCTAssertEqual(result.error?.title, "Query Error")
    XCTAssertEqual(result.error?.message, "Something broke")
  }
  
  // MARK: - Reading a response once

  /// Hands out its responses in turn, repeating the last, and keeps the body of each request.
  final class SequenceURLSession: URLSessionProtocol {
    var responses: [String]
    var requestBodies = [String]()

    init(_ responses: [String]) {
      self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
      requestBodies.append(request.httpBody.map { String(decoding: $0, as: UTF8.self) } ?? "")
      let body = responses.count > 1 ? responses.removeFirst() : responses[0]
      let response = HTTPURLResponse(url: request.url ?? URL(fileURLWithPath: "example.org"),
                                     statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (Data(body.utf8), response)
    }
  }

  let histogramRequest = SearchHistogramRequest(field: "@timestamp",
                                                from: Date(timeIntervalSince1970: 1_779_999_900),
                                                to: Date(timeIntervalSince1970: 1_779_999_990),
                                                interval: HistogramInterval(seconds: 30, expression: "30s", title: "30 seconds"),
                                                legacyInterval: false)

  let documentsWithHistogram = """
  {"took":3,"hits":{"total":{"value":7,"relation":"eq"},"hits":[
    {"_id":"1","_source":{"message":"hello","user":{"name":"ryan"}}},
    {"_id":"2","_source":{"message":"bye","user":{"id":4}}}]},
   "aggregations":{"over_time":{"buckets":[
    {"key":1779999900000,"doc_count":4},{"key":1779999930000,"doc_count":0},{"key":1779999960000,"doc_count":3}]}}}
  """

  let aggregationError = """
  {"error":{"root_cause":[{"type":"illegal_argument_exception",
    "reason":"Field [created] of type [keyword] is not supported for aggregation [date_histogram]"}]},"status":400}
  """

  func testCallReadsDocumentsAndHistogramFromOneResponse() async throws {
    let session = SequenceURLSession([documentsWithHistogram])
    Request.mockedSession = session
    defer { Request.mockedSession = nil }

    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails,
                                         index: "testIndex", limitObj: limitObj, histogram: histogramRequest)

    XCTAssertNil(result.error)
    XCTAssertEqual(session.requestBodies.count, 1)
    XCTAssertEqual(result.results.count, 2)
    XCTAssertEqual(result.hits, 7)
    XCTAssertEqual(result.fields?.map(\.squashedString), ["message", "user.id", "user.name"])
    XCTAssertEqual(result.rows.map { $0.keys.elements }, [["message", "user.name"], ["message", "user.id"]])
    XCTAssertEqual(result.rows.first?["user.name"] as? [String], ["ryan"])
    XCTAssertEqual(result.rows.last?["user.id"] as? [String], ["4"])
    XCTAssertEqual(result.histogram?.buckets.map(\.count), [4, 0, 3])
  }

  func testCallRetriesWithoutHistogramWhenAggregationFails() async throws {
    let documentsOnly = """
    {"took":1,"hits":{"total":{"value":1,"relation":"eq"},"hits":[{"_id":"1","_source":{"message":"hello"}}]}}
    """
    let session = SequenceURLSession([aggregationError, documentsOnly])
    Request.mockedSession = session
    defer { Request.mockedSession = nil }

    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails,
                                         index: "testIndex", limitObj: limitObj, histogram: histogramRequest)

    // Asked with the histogram, then again without it
    XCTAssertEqual(session.requestBodies.map { $0.contains(SearchHistogram.aggregationName) }, [true, false])
    XCTAssertNil(result.error, "The retry's documents replace the aggregation error")
    XCTAssertEqual(result.results.count, 1)
    XCTAssertEqual(result.hits, 1)
    XCTAssertNil(result.histogram)
  }

  /// A page of wide documents: ten groups of 28 fields, plus arrays, about 6 KB each.
  static func widePage(documents: Int) -> String {
    let hits = (0..<documents).map { i -> [String: Any] in
      var source: [String: Any] = ["@timestamp": "2026-10-06T00:00:31Z"]
      for group in 0..<10 {
        var fields: [String: Any] = ["tags": ["a", "b", "c"], "items": [["id": i, "name": "n\(i)"], ["id": i + 1]]]
        for field in 0..<28 {
          fields["f\(field)"] = field % 3 == 0 ? "value-\(i)-\(field)" : Double(i * field) / 7.0
        }
        source["group\(group)"] = fields
      }
      return ["_id": "\(i)", "_source": source]
    }
    let page: [String: Any] = ["hits": ["total": ["value": 10_000], "hits": hits]]
    return String(decoding: try! JSONSerialization.data(withJSONObject: page), as: UTF8.self)
  }

  /// Times taken on the main thread, to find how long it went without a turn.
  @MainActor final class MainThreadTicks {
    var times = [UInt64]()

    var longestGap: UInt64 {
      zip(times, times.dropFirst()).map { $1 - $0 }.max() ?? 0
    }
  }

  @MainActor
  func testCallKeepsMainThreadFreeWhileReading() async throws {
    Request.mockedSession = SequenceURLSession([Self.widePage(documents: 500)])
    defer { Request.mockedSession = nil }

    let ticks = MainThreadTicks()
    let ticker = Task { @MainActor in
      while !Task.isCancelled {
        ticks.times.append(DispatchTime.now().uptimeNanoseconds)
        try? await Task.sleep(nanoseconds: 2_000_000)
      }
    }
    let start = DispatchTime.now().uptimeNanoseconds
    ticks.times.append(start)

    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails,
                                         index: "testIndex", limitObj: limitObj)

    let end = DispatchTime.now().uptimeNanoseconds
    ticks.times.append(end)
    ticker.cancel()

    XCTAssertNil(result.error)
    XCTAssertEqual(result.results.count, 500)
    XCTAssertEqual(result.rows.count, 500)
    // Reading the page takes most of the search; on the main thread it would leave one long gap
    let elapsed = Double(end - start)
    XCTAssertLessThan(Double(ticks.longestGap), elapsed * 0.5,
                      "Main thread was busy for \(ticks.longestGap / 1_000_000) ms of a \(Int(elapsed / 1_000_000)) ms search")
  }

  func testCallDoesNotRetrySortErrorsThatMentionAggregations() async throws {
    let sortError = """
    {"error":{"root_cause":[{"type":"illegal_argument_exception","reason":"Text fields are not optimised for operations that require per-document field data like aggregations and sorting. Alternatively, set fielddata=true on [message] in order to load field data"}]},"status":400}
    """
    let session = SequenceURLSession([sortError])
    Request.mockedSession = session
    defer { Request.mockedSession = nil }

    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails,
                                         index: "testIndex", limitObj: limitObj, histogram: histogramRequest)

    XCTAssertEqual(session.requestBodies.count, 1, "Not the histogram's fault, so not retried")
    XCTAssertEqual(result.error?.title, "illegal_argument_exception")
  }

  func testCallDoesNotRetryOtherErrors() async throws {
    let queryError = """
    {"error":{"root_cause":[{"type":"query_shard_exception","reason":"Failed to parse query [status:(]"}]},"status":400}
    """
    let session = SequenceURLSession([queryError])
    Request.mockedSession = session
    defer { Request.mockedSession = nil }

    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails,
                                         index: "testIndex", limitObj: limitObj, histogram: histogramRequest)

    XCTAssertEqual(session.requestBodies.count, 1)
    XCTAssertEqual(result.error?.title, "query_shard_exception")
    XCTAssertEqual(result.error?.message, "Failed to parse query [status:(]")
  }

  func testParseReadsResponseOnce() async throws {
    let response = ServerResponse()
    response.parsed = documentsWithHistogram

    let maybeParsed = await SearchRender.parse(response, histogram: nil)
    let parsed = try XCTUnwrap(maybeParsed)
    let fromString = Search.getObjects(input: documentsWithHistogram)

    XCTAssertNotNil(parsed.json?["aggregations"])
    XCTAssertEqual(parsed.result.hitCount, fromString.hitCount)
    XCTAssertEqual(parsed.result.data.count, fromString.data.count)
    XCTAssertEqual(parsed.result.fields.map(\.squashedString), fromString.fields.map(\.squashedString))
    XCTAssertFalse(SearchRender.failedOnHistogram(parsed, field: "@timestamp"))
  }

  func testParseSkipsResponsesWithRequestErrors() async {
    let failed = ServerResponse(error: ResponseError(title: "Request Error", message: "offline", type: .critical))
    failed.parsed = aggregationError
    let parsedFailure = await SearchRender.parse(failed, histogram: nil)
    XCTAssertNil(parsedFailure)
    XCTAssertFalse(SearchRender.failedOnHistogram(nil, field: "@timestamp"))

    let parsedEmpty = await SearchRender.parse(ServerResponse(), histogram: nil)
    XCTAssertNil(parsedEmpty, "No body, nothing to read")
  }

  func testFailedOnHistogramOnlyForAggregationErrors() async {
    let aggregation = ServerResponse()
    aggregation.parsed = aggregationError
    let parsedAggregation = await SearchRender.parse(aggregation, histogram: histogramRequest)
    XCTAssertTrue(SearchRender.failedOnHistogram(parsedAggregation, field: "@timestamp"))

    let query = ServerResponse()
    query.parsed = #"{"error":{"root_cause":[{"type":"t","reason":"no such index [logs]"}]}}"#
    let parsedQuery = await SearchRender.parse(query, histogram: histogramRequest)
    XCTAssertFalse(SearchRender.failedOnHistogram(parsedQuery, field: "@timestamp"))
  }

  @MainActor
  func testReadBuildsHistogramAwayFromMainThread() async {
    // read checks it isn't on the main thread in Debug builds, even when asked from the main actor
    let parsed = await SearchRender.read(documentsWithHistogram, histogram: histogramRequest)
    XCTAssertEqual(parsed.result.data.count, 2)
    XCTAssertEqual(parsed.result.rows.count, 2)
    XCTAssertEqual(parsed.histogram?.buckets.map(\.count), [4, 0, 3])

    let withoutHistogram = await SearchRender.read(documentsWithHistogram, histogram: nil)
    XCTAssertNil(withoutHistogram.histogram, "No histogram unless one was asked for")
    XCTAssertEqual(withoutHistogram.result.data.count, 2)
  }

  func testSortObjectProperties() {
    // Test the properties of SortObject
    XCTAssertEqual(sortObject.order, .Ascending)
    XCTAssertEqual(sortObject.field, squasedFieldsArray, "Sort field should match the initialized SquashedFieldsArray")
  }

#if os(macOS)
  func testFieldVisibilityCheck() {
    let field1 = SquashedFieldsArray(squashedString: "fieldA")
    field1.visible = true
    let field2 = SquashedFieldsArray(squashedString: "fieldB")
    field2.visible = false
    let fields = [field1, field2]

    XCTAssertTrue(macosDocumentDetailView.isFieldVisible("fieldA", in: fields))
    XCTAssertFalse(macosDocumentDetailView.isFieldVisible("fieldB", in: fields))
    XCTAssertFalse(macosDocumentDetailView.isFieldVisible("nonexistent", in: fields))
  }

  func testFieldVisibilityFallbackToOnlyVisibleFields() {
    let fields = [SquashedFieldsArray]()
    let visibleField = SquashedFieldsArray(squashedString: "fieldC")
    visibleField.visible = true
    let onlyVisibleFields = [visibleField]

    XCTAssertTrue(macosDocumentDetailView.isFieldVisible("fieldC", in: fields, onlyVisibleFields: onlyVisibleFields))
    XCTAssertFalse(macosDocumentDetailView.isFieldVisible("unknown", in: fields, onlyVisibleFields: onlyVisibleFields))
  }

  func testFieldTypeComesFromMapping() {
    let count = SquashedFieldsArray(squashedString: "count")
    count.type = "float"
    let symbol = SquashedFieldsArray(squashedString: "symbol")
    symbol.type = "keyword"

    XCTAssertEqual(macosDocumentDetailView.fieldType("count", in: [count, symbol]), "float")
    XCTAssertEqual(macosDocumentDetailView.fieldType("symbol", in: [count, symbol]), "keyword")
    XCTAssertNil(macosDocumentDetailView.fieldType("unmapped", in: [count, symbol]))
  }

  func testFieldTypeSkipsUntypedEntries() {
    // Toggling an unmapped field adds an untyped entry to fields; the typed one should still win.
    let untyped = SquashedFieldsArray(squashedString: "user.id")
    let typed = SquashedFieldsArray(squashedString: "user.id")
    typed.type = "long"

    XCTAssertEqual(macosDocumentDetailView.fieldType("user.id", in: [untyped], onlyVisibleFields: [typed]), "long")
    XCTAssertNil(macosDocumentDetailView.fieldType("user.id", in: [untyped]))
  }

  func testToggleFieldVisibilityExistingField() {
    let field = SquashedFieldsArray(squashedString: "status")
    field.visible = false
    var fields = [field]
    var onlyVisibleFields = [SquashedFieldsArray]()

    // Toggle on
    let result1 = macosDocumentDetailView.toggleFieldVisibility("status", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(result1)
    XCTAssertTrue(field.visible)
    XCTAssertTrue(onlyVisibleFields.contains(where: { $0.squashedString == "status" && $0.visible }))

    // Toggle off
    let result2 = macosDocumentDetailView.toggleFieldVisibility("status", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertFalse(result2)
    XCTAssertFalse(field.visible)
    XCTAssertFalse(onlyVisibleFields.first(where: { $0.squashedString == "status" })?.visible ?? true)
  }

  func testToggleFieldVisibilityNewField() {
    var fields = [SquashedFieldsArray]()
    var onlyVisibleFields = [SquashedFieldsArray]()

    let result = macosDocumentDetailView.toggleFieldVisibility("user.name", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(result)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(fields[0].squashedString, "user.name")
    XCTAssertEqual(fields[0].fieldParts, ["user", "name"])
    XCTAssertTrue(fields[0].visible)
    XCTAssertEqual(onlyVisibleFields.count, 1)
    XCTAssertEqual(onlyVisibleFields[0].squashedString, "user.name")
    XCTAssertTrue(onlyVisibleFields[0].visible)
    // Verify object reference identity is preserved
    XCTAssertTrue(fields[0] === onlyVisibleFields[0], "fields and onlyVisibleFields should reference the exact same instance")
  }

  func testToggleFieldVisibilityPreExistingOnlyVisibleField() {
    var fields = [SquashedFieldsArray]()
    let unmappedField = SquashedFieldsArray(squashedString: "dynamic.tag", fieldParts: ["dynamic", "tag"])
    unmappedField.type = "keyword"
    unmappedField.visible = false
    var onlyVisibleFields = [unmappedField]

    // Toggle on
    let result = macosDocumentDetailView.toggleFieldVisibility("dynamic.tag", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(result)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(fields[0].squashedString, "dynamic.tag")
    XCTAssertEqual(fields[0].type, "keyword")
    XCTAssertTrue(fields[0].visible)
    XCTAssertTrue(onlyVisibleFields[0].visible)
    XCTAssertTrue(fields[0] === onlyVisibleFields[0], "Existing onlyVisibleField should be reused in fields")
  }

  func testToggleFieldVisibilityMultipleCycles() {
    let field = SquashedFieldsArray(squashedString: "log.level", fieldParts: ["log", "level"])
    var fields = [field]
    var onlyVisibleFields = [field]

    // Cycle 1: On
    _ = macosDocumentDetailView.toggleFieldVisibility("log.level", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(field.visible)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(onlyVisibleFields.count, 1)

    // Cycle 1: Off
    _ = macosDocumentDetailView.toggleFieldVisibility("log.level", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertFalse(field.visible)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(onlyVisibleFields.count, 1)

    // Cycle 2: On
    _ = macosDocumentDetailView.toggleFieldVisibility("log.level", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(field.visible)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(onlyVisibleFields.count, 1)

    // Cycle 2: Off
    _ = macosDocumentDetailView.toggleFieldVisibility("log.level", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertFalse(field.visible)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(onlyVisibleFields.count, 1)
  }

  func testToggleFieldVisibilityDeepNestedKey() {
    var fields = [SquashedFieldsArray]()
    var onlyVisibleFields = [SquashedFieldsArray]()

    let result = macosDocumentDetailView.toggleFieldVisibility("a.b.c.d", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(result)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(fields[0].fieldParts, ["a", "b", "c", "d"])
    XCTAssertTrue(fields[0] === onlyVisibleFields[0])
  }

  func testSelectionStateOfKeys() {
    let shown = SquashedFieldsArray(squashedString: "cpu0")
    shown.visible = true
    let hidden = SquashedFieldsArray(squashedString: "cpu1")
    hidden.visible = false
    let fields = [shown, hidden]

    XCTAssertEqual(macosDocumentDetailView.selectionState(of: ["cpu0"], in: fields), .on)
    XCTAssertEqual(macosDocumentDetailView.selectionState(of: ["cpu1", "unmapped"], in: fields), .off)
    XCTAssertEqual(macosDocumentDetailView.selectionState(of: ["cpu0", "cpu1"], in: fields), .mixed)
    XCTAssertEqual(macosDocumentDetailView.selectionState(of: [], in: fields), .off)
  }

  func testDocumentFieldsCountLabel() {
    XCTAssertEqual(DocumentFieldsGrid.countLabel(total: 48, selected: 12), "48 fields · 12 selected")
    XCTAssertEqual(DocumentFieldsGrid.countLabel(total: 48, selected: 0), "48 fields")
    XCTAssertEqual(DocumentFieldsGrid.countLabel(total: 1, selected: 1), "1 field · 1 selected")
  }

  func testToggleAllFieldsVisibilityShowsAllWhenSomeAreHidden() {
    let shown = SquashedFieldsArray(squashedString: "cpu0")
    shown.visible = true
    let hidden = SquashedFieldsArray(squashedString: "cpu1")
    hidden.visible = false
    let untouched = SquashedFieldsArray(squashedString: "memory")
    untouched.visible = false
    var fields = [shown, hidden, untouched]
    var onlyVisibleFields = [shown]

    let result = macosDocumentDetailView.toggleAllFieldsVisibility(
      ["cpu0", "cpu1", "dynamic.tag"], fields: &fields, onlyVisibleFields: &onlyVisibleFields)

    XCTAssertTrue(result)
    XCTAssertTrue(shown.visible, "An already shown field should stay shown")
    XCTAssertTrue(hidden.visible)
    XCTAssertTrue(macosDocumentDetailView.isFieldVisible("dynamic.tag", in: fields), "An unmapped field should be added")
    XCTAssertFalse(untouched.visible, "Fields outside the keys should not change")
    XCTAssertEqual(onlyVisibleFields.map(\.squashedString).sorted(), ["cpu0", "cpu1", "dynamic.tag"])
  }

  func testToggleAllFieldsVisibilityHidesAllWhenAllAreShown() {
    let first = SquashedFieldsArray(squashedString: "cpu0")
    first.visible = true
    let second = SquashedFieldsArray(squashedString: "cpu1")
    second.visible = true
    let untouched = SquashedFieldsArray(squashedString: "memory")
    untouched.visible = true
    var fields = [first, second, untouched]
    var onlyVisibleFields = [first, second, untouched]

    let result = macosDocumentDetailView.toggleAllFieldsVisibility(
      ["cpu0", "cpu1"], fields: &fields, onlyVisibleFields: &onlyVisibleFields)

    XCTAssertFalse(result)
    XCTAssertFalse(first.visible)
    XCTAssertFalse(second.visible)
    XCTAssertTrue(untouched.visible, "Fields outside the keys should not change")
    XCTAssertEqual(macosDocumentDetailView.selectionState(of: ["cpu0", "cpu1"], in: fields), .off)
  }

  /// Counts how often each field announces a change.
  func changeCounts(_ fields: [SquashedFieldsArray]) -> (counts: () -> [Int], cancellables: [AnyCancellable]) {
    var counts = Array(repeating: 0, count: fields.count)
    let cancellables = fields.enumerated().map { index, field in
      field.objectWillChange.sink { counts[index] += 1 }
    }
    return ({ counts }, cancellables)
  }

  func testToggleAllFieldsVisibilityAnnouncesEachChangedFieldOnce() {
    let shown = SquashedFieldsArray(squashedString: "cpu0")
    shown.visible = true
    let hidden = SquashedFieldsArray(squashedString: "cpu1")
    let hiddenToo = SquashedFieldsArray(squashedString: "cpu2")
    var fields = [shown, hidden, hiddenToo]
    var onlyVisibleFields = [shown]
    let changes = changeCounts(fields)

    macosDocumentDetailView.toggleAllFieldsVisibility(
      ["cpu0", "cpu1", "cpu2"], fields: &fields, onlyVisibleFields: &onlyVisibleFields)

    XCTAssertEqual(changes.counts(), [0, 1, 1], "Only fields that change should announce it, and only once")
    withExtendedLifetime(changes.cancellables) {}
  }

  func testToggleFieldVisibilityAnnouncesOnce() {
    let field = SquashedFieldsArray(squashedString: "status")
    var fields = [field]
    var onlyVisibleFields = [field]
    let changes = changeCounts(fields)

    macosDocumentDetailView.toggleFieldVisibility("status", fields: &fields, onlyVisibleFields: &onlyVisibleFields)

    XCTAssertEqual(changes.counts(), [1], "The same field in both lists should only announce the change once")
    withExtendedLifetime(changes.cancellables) {}
  }

  func testToggleAllFieldsVisibilityUpdatesSeparateCopiesInBothLists() {
    let mapped = SquashedFieldsArray(squashedString: "cpu0")
    let inResults = SquashedFieldsArray(squashedString: "cpu0")
    var fields = [mapped]
    var onlyVisibleFields = [inResults]

    XCTAssertTrue(macosDocumentDetailView.toggleAllFieldsVisibility(
      ["cpu0"], fields: &fields, onlyVisibleFields: &onlyVisibleFields))
    XCTAssertTrue(mapped.visible)
    XCTAssertTrue(inResults.visible)
    XCTAssertEqual(onlyVisibleFields.count, 1, "A field already in the list shouldn't be added again")

    XCTAssertFalse(macosDocumentDetailView.toggleAllFieldsVisibility(
      ["cpu0"], fields: &fields, onlyVisibleFields: &onlyVisibleFields))
    XCTAssertFalse(mapped.visible)
    XCTAssertFalse(inResults.visible)
  }

  func testToggleAllFieldsVisibilityAddsEachUnmappedKeyOnce() {
    var fields = [SquashedFieldsArray]()
    var onlyVisibleFields = [SquashedFieldsArray]()

    macosDocumentDetailView.toggleAllFieldsVisibility(
      ["dynamic.a", "dynamic.b"], fields: &fields, onlyVisibleFields: &onlyVisibleFields)

    XCTAssertEqual(fields.map(\.squashedString), ["dynamic.a", "dynamic.b"])
    XCTAssertEqual(fields.map(\.fieldParts), [["dynamic", "a"], ["dynamic", "b"]])
    XCTAssertTrue(zip(fields, onlyVisibleFields).allSatisfy { $0 === $1 && $0.visible },
                  "Both lists should hold the same shown field for each key")
  }

  func testSyncVisibilityPreservesMappedFields() {
    let source1 = SquashedFieldsArray(squashedString: "fieldA")
    source1.visible = true
    let source2 = SquashedFieldsArray(squashedString: "fieldB")
    source2.visible = false
    let sourceFields = [source1, source2]
    let sourceOnlyVisible = [SquashedFieldsArray]()

    let target1 = SquashedFieldsArray(squashedString: "fieldA")
    target1.visible = false
    let target2 = SquashedFieldsArray(squashedString: "fieldB")
    target2.visible = false
    let target3 = SquashedFieldsArray(squashedString: "fieldC")
    target3.visible = false
    var targetFields = [target1, target2, target3]
    var targetOnlyVisible = [SquashedFieldsArray]()

    macosSearchMainView.syncVisibility(
      sourceFields: sourceFields,
      sourceOnlyVisible: sourceOnlyVisible,
      targetFields: &targetFields,
      targetOnlyVisible: &targetOnlyVisible
    )

    XCTAssertTrue(target1.visible, "fieldA was visible in source and should be marked visible in target")
    XCTAssertFalse(target2.visible, "fieldB was false in source and should remain false")
    XCTAssertFalse(target3.visible, "fieldC was not in source and should remain false")
  }

  func testSyncVisibilityPreservesOnlyVisibleFields() {
    let source1 = SquashedFieldsArray(squashedString: "fieldA")
    source1.visible = true
    let sourceFields = [source1]

    let sourceVis1 = SquashedFieldsArray(squashedString: "fieldB")
    sourceVis1.visible = true
    let sourceVis2 = SquashedFieldsArray(squashedString: "fieldC")
    sourceVis2.visible = false
    let sourceOnlyVisible = [sourceVis1, sourceVis2]

    var targetFields = [SquashedFieldsArray]()

    let targetVis1 = SquashedFieldsArray(squashedString: "fieldA")
    targetVis1.visible = false
    let targetVis2 = SquashedFieldsArray(squashedString: "fieldB")
    targetVis2.visible = false
    let targetVis3 = SquashedFieldsArray(squashedString: "fieldC")
    targetVis3.visible = false
    let targetVis4 = SquashedFieldsArray(squashedString: "fieldD")
    targetVis4.visible = false
    var targetOnlyVisible = [targetVis1, targetVis2, targetVis3, targetVis4]

    macosSearchMainView.syncVisibility(
      sourceFields: sourceFields,
      sourceOnlyVisible: sourceOnlyVisible,
      targetFields: &targetFields,
      targetOnlyVisible: &targetOnlyVisible
    )

    XCTAssertTrue(targetVis1.visible, "fieldA was visible in sourceFields, should be visible in targetOnlyVisible")
    XCTAssertTrue(targetVis2.visible, "fieldB was visible in sourceOnlyVisible, should be visible in targetOnlyVisible")
    XCTAssertFalse(targetVis3.visible, "fieldC was false in sourceOnlyVisible, should remain false")
    XCTAssertFalse(targetVis4.visible, "fieldD was not in visibleKeys, should remain false")
  }

  func testSyncVisibilityRetainsUnmappedDynamicFields() {
    let mappedField = SquashedFieldsArray(squashedString: "mapped.field")
    mappedField.visible = true
    let dynamicField = SquashedFieldsArray(squashedString: "dynamic.field", fieldParts: ["dynamic", "field"])
    dynamicField.type = "keyword"
    dynamicField.visible = true
    let hiddenDynamicField = SquashedFieldsArray(squashedString: "hidden.field", fieldParts: ["hidden", "field"])
    hiddenDynamicField.visible = false

    let sourceFields = [mappedField, dynamicField, hiddenDynamicField]
    let sourceOnlyVisible = [SquashedFieldsArray]()

    let targetMapped = SquashedFieldsArray(squashedString: "mapped.field")
    targetMapped.visible = false
    let targetOther = SquashedFieldsArray(squashedString: "other.mapped")
    targetOther.visible = false
    var targetFields = [targetMapped, targetOther]
    var targetOnlyVisible = [SquashedFieldsArray]()

    macosSearchMainView.syncVisibility(
      sourceFields: sourceFields,
      sourceOnlyVisible: sourceOnlyVisible,
      targetFields: &targetFields,
      targetOnlyVisible: &targetOnlyVisible
    )

    XCTAssertEqual(targetFields.count, 3, "targetFields should retain the unmapped dynamic field that was visible")
    XCTAssertTrue(targetMapped.visible, "mapped.field should be marked visible")
    XCTAssertFalse(targetOther.visible, "other.mapped should remain false")
    XCTAssertTrue(targetFields.contains(where: { $0.squashedString == "dynamic.field" && $0.visible }), "dynamic.field should be preserved with visible=true")
    XCTAssertFalse(targetFields.contains(where: { $0.squashedString == "hidden.field" }), "hidden unmapped fields should not be added")
  }

  func testSyncVisibilityEmptySourcesDoesNotModifyTargets() {
    let target1 = SquashedFieldsArray(squashedString: "fieldA")
    target1.visible = false
    var targetFields = [target1]

    let targetVis1 = SquashedFieldsArray(squashedString: "fieldB")
    targetVis1.visible = false
    var targetOnlyVisible = [targetVis1]

    macosSearchMainView.syncVisibility(
      sourceFields: [],
      sourceOnlyVisible: [],
      targetFields: &targetFields,
      targetOnlyVisible: &targetOnlyVisible
    )

    XCTAssertEqual(targetFields.count, 1)
    XCTAssertFalse(target1.visible)
    XCTAssertEqual(targetOnlyVisible.count, 1)
    XCTAssertFalse(targetVis1.visible)
  }

  func testSyncVisibilityPreservesMultipleFieldsWithoutDuplicates() {
    let dyn1 = SquashedFieldsArray(squashedString: "dyn1", fieldParts: ["dyn1"])
    dyn1.visible = true
    let dyn2 = SquashedFieldsArray(squashedString: "dyn1", fieldParts: ["dyn1"])
    dyn2.visible = true
    let sourceFields = [dyn1, dyn2]
    let sourceOnlyVisible = [SquashedFieldsArray]()

    var targetFields = [SquashedFieldsArray]()
    var targetOnlyVisible = [SquashedFieldsArray]()

    macosSearchMainView.syncVisibility(
      sourceFields: sourceFields,
      sourceOnlyVisible: sourceOnlyVisible,
      targetFields: &targetFields,
      targetOnlyVisible: &targetOnlyVisible
    )

    XCTAssertEqual(targetFields.count, 1, "Duplicate visible source fields should not create duplicates in targetFields")
    XCTAssertEqual(targetFields[0].squashedString, "dyn1")
    XCTAssertTrue(targetFields[0].visible)
  }

  func testKeyedCacheLogic() {
    let hostId = UUID()
    let otherHostId = UUID()
    let index = "test-index"
    let otherIndex = "other-index"

    let currentKey = macosSearchMainView.computeCacheKey(hostId: hostId, index: index)
    XCTAssertEqual(currentKey, "\(hostId.uuidString)|\(index)")

    let field = SquashedFieldsArray(squashedString: "fieldA")
    let fields = [field]

    // Cache hit: same host, same index, non-empty fields
    let hit = macosSearchMainView.isCacheValid(fields: fields, fieldsCacheKey: currentKey, currentKey: currentKey)
    XCTAssertTrue(hit, "Cache should be valid when host, index, and non-empty fields match")

    // Cache miss: empty fields
    let emptyMiss = macosSearchMainView.isCacheValid(fields: [], fieldsCacheKey: currentKey, currentKey: currentKey)
    XCTAssertFalse(emptyMiss, "Cache should be invalid when fields are empty")

    // Cache miss: different index
    let otherIndexKey = macosSearchMainView.computeCacheKey(hostId: hostId, index: otherIndex)
    let indexMiss = macosSearchMainView.isCacheValid(fields: fields, fieldsCacheKey: currentKey, currentKey: otherIndexKey)
    XCTAssertFalse(indexMiss, "Cache should be invalid when index changes")

    // Cache miss: different host
    let otherHostKey = macosSearchMainView.computeCacheKey(hostId: otherHostId, index: index)
    let hostMiss = macosSearchMainView.isCacheValid(fields: fields, fieldsCacheKey: currentKey, currentKey: otherHostKey)
    XCTAssertFalse(hostMiss, "Cache should be invalid when host changes")
  }

  func testSyncVisibilityOnReusePathDoesNotResurrectHiddenFields() {
    let fieldA = SquashedFieldsArray(squashedString: "fieldA")
    fieldA.visible = false
    let fieldB = SquashedFieldsArray(squashedString: "fieldB")
    fieldB.visible = true
    let fields = [fieldA, fieldB]

    let visA = SquashedFieldsArray(squashedString: "fieldA")
    visA.visible = false
    let visB = SquashedFieldsArray(squashedString: "fieldB")
    visB.visible = false
    var onlyVisibleFields = [visA, visB]

    var unused = [SquashedFieldsArray]()
    macosSearchMainView.syncVisibility(
      sourceFields: fields,
      sourceOnlyVisible: [],
      targetFields: &unused,
      targetOnlyVisible: &onlyVisibleFields
    )

    XCTAssertFalse(fieldA.visible, "Hidden field in fields must remain false")
    XCTAssertTrue(fieldB.visible, "Visible field in fields must remain true")
    XCTAssertFalse(visA.visible, "Hidden field must not be resurrected in onlyVisibleFields")
    XCTAssertTrue(visB.visible, "Visible field must be marked visible in onlyVisibleFields")
  }

  func testFilterFieldsByMode() {
    let timestamp = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    timestamp.visible = true
    let message = SquashedFieldsArray(squashedString: "message", fieldParts: ["message"])
    message.visible = true
    let host = SquashedFieldsArray(squashedString: "host.name", fieldParts: ["host", "name"])
    let level = SquashedFieldsArray(squashedString: "level", fieldParts: ["level"])

    let fields = [timestamp, message, host, level]
    let inDocs = [
      SquashedFieldsArray(squashedString: "message", fieldParts: ["message"]),
      SquashedFieldsArray(squashedString: "host.name", fieldParts: ["host", "name"]),
    ]

    func names(_ mode: FieldListMode, _ search: String = "") -> [String] {
      macosSearchFieldSheetView.filterFields(mode: mode,
                                             fields: fields,
                                             onlyVisibleFields: inDocs,
                                             searchText: search).map { $0.squashedString }
    }

    XCTAssertEqual(names(.mapped), ["timestamp", "message", "host.name", "level"])
    XCTAssertEqual(names(.inDocuments), ["message", "host.name"])
    XCTAssertEqual(names(.selected), ["timestamp", "message"])
    XCTAssertEqual(names(.selected, "mess"), ["message"])
    // The search ignores case, so lowercase text finds capitalised field names and vice versa
    XCTAssertEqual(names(.selected, "MESS"), ["message"])
    XCTAssertEqual(names(.mapped, "Host"), ["host.name"])
    // A search with no matches falls back to the whole list, as the other modes do
    XCTAssertEqual(names(.selected, "zzz"), ["timestamp", "message"])

    message.visible = false
    XCTAssertEqual(names(.selected), ["timestamp"])
    timestamp.visible = false
    XCTAssertEqual(names(.selected), [])
  }

  func testFilterFieldsMatchesDataViewLabels() {
    let price = SquashedFieldsArray(squashedString: "FILL_PRICE", fieldParts: ["FILL_PRICE"])
    let symbol = SquashedFieldsArray(squashedString: "SYMBOL", fieldParts: ["SYMBOL"])
    let labels = ["FILL_PRICE": "Fill price"]

    func names(_ search: String, labels: [String: String]) -> [String] {
      macosSearchFieldSheetView.filterFields(mode: .mapped,
                                             fields: [price, symbol],
                                             onlyVisibleFields: [],
                                             searchText: search,
                                             labels: labels).map { $0.squashedString }
    }

    // "fill p" is only in the label, so it finds the field by its label
    XCTAssertEqual(names("fill p", labels: labels), ["FILL_PRICE"])
    XCTAssertEqual(names("SYMB", labels: labels), ["SYMBOL"])
    // Without labels nothing matches, so every field is listed, as before
    XCTAssertEqual(names("fill p", labels: [:]), ["FILL_PRICE", "SYMBOL"])
  }

  func testSetFieldVisibilitySyncsBothArrays() {
    let item = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    item.visible = false
    let itemInFields = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    itemInFields.visible = false
    let itemInOnlyVis = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    itemInOnlyVis.visible = false

    let fields = [itemInFields]
    let onlyVisible = [itemInOnlyVis]

    // Toggle on
    let changed = macosSearchFieldSheetView.setFieldVisibility(
      item: item,
      visible: true,
      fields: fields,
      onlyVisibleFields: onlyVisible
    )
    XCTAssertTrue(changed)
    XCTAssertTrue(item.visible)
    XCTAssertTrue(itemInFields.visible)
    XCTAssertTrue(itemInOnlyVis.visible)

    // Redundant toggle on should return false
    let redundant = macosSearchFieldSheetView.setFieldVisibility(
      item: item,
      visible: true,
      fields: fields,
      onlyVisibleFields: onlyVisible
    )
    XCTAssertFalse(redundant)

    // Toggle off
    let changedOff = macosSearchFieldSheetView.setFieldVisibility(
      item: item,
      visible: false,
      fields: fields,
      onlyVisibleFields: onlyVisible
    )
    XCTAssertTrue(changedOff)
    XCTAssertFalse(item.visible)
    XCTAssertFalse(itemInFields.visible)
    XCTAssertFalse(itemInOnlyVis.visible)
  }

  func testBodyFilteredFieldsExcludesDateField() {
    let dateField = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    dateField.visible = true
    let bodyField1 = SquashedFieldsArray(squashedString: "threadCount", fieldParts: ["threadCount"])
    bodyField1.visible = true
    let bodyField2 = SquashedFieldsArray(squashedString: "message", fieldParts: ["message"])
    bodyField2.visible = false

    let allFields = [dateField, bodyField1, bodyField2]

    let bodyFiltered = macosSearchMainView.computeBodyFilteredFields(
      fields: allFields,
      activeDateField: dateField
    )

    XCTAssertEqual(bodyFiltered.count, 1)
    XCTAssertEqual(bodyFiltered[0].squashedString, "threadCount")
    XCTAssertFalse(bodyFiltered.contains(where: { $0.squashedString == "timestamp" }))
    XCTAssertFalse(bodyFiltered.contains(where: { $0.squashedString == "message" }))
  }

  func testShowDateHeaderReflectsDateFieldVisibility() {
    let dateField = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    dateField.visible = true
    let otherField = SquashedFieldsArray(squashedString: "message", fieldParts: ["message"])
    otherField.visible = true

    // Active and visible -> true
    XCTAssertTrue(macosSearchMainView.shouldShowDateHeader(fields: [dateField, otherField], activeDateField: dateField))

    // Active but hidden -> false
    dateField.visible = false
    XCTAssertFalse(macosSearchMainView.shouldShowDateHeader(fields: [dateField, otherField], activeDateField: dateField))

    // Active date field is nil -> false
    XCTAssertFalse(macosSearchMainView.shouldShowDateHeader(fields: [dateField, otherField], activeDateField: nil))

    // Active date field not in fields -> false
    let missingDateField = SquashedFieldsArray(squashedString: "missing", fieldParts: ["missing"])
    missingDateField.visible = true
    XCTAssertFalse(macosSearchMainView.shouldShowDateHeader(fields: [dateField, otherField], activeDateField: missingDateField))
  }

  func testUnconditionalDateRemovalFromItem() {
    var item = OrderedDictionary<String, Any>()
    item["timestamp"] = ["2026-09-20T12:00:00Z"]
    item["message"] = ["Server started"]

    var itemWithoutDate = item
    itemWithoutDate.removeValue(forKey: "timestamp")

    // Unfiltered path: filteredFields is empty
    let unfilteredResult = ElasticDocumentBuilder.exportFlatValues(input: itemWithoutDate, filteredFields: [])
    let unfilteredValues = unfilteredResult.map { $0.value }
    XCTAssertTrue(unfilteredValues.contains("message"))
    XCTAssertTrue(unfilteredValues.contains("Server started"))
    XCTAssertFalse(unfilteredValues.contains("timestamp"))
    XCTAssertFalse(unfilteredValues.contains("2026-09-20T12:00:00Z"))

    // Filtered path: filteredFields has message
    let messageField = SquashedFieldsArray(squashedString: "message", fieldParts: ["message"])
    messageField.visible = true
    let filteredResult = ElasticDocumentBuilder.exportFlatValues(input: itemWithoutDate, filteredFields: [messageField])
    let filteredValues = filteredResult.map { $0.value }
    XCTAssertTrue(filteredValues.contains("message"))
    XCTAssertTrue(filteredValues.contains("Server started"))
    XCTAssertFalse(filteredValues.contains("timestamp"))
  }

  func testRowVisibilityWithBodyFiltersExcludesMissingFields() {
    // 1. Body filtered, missing body fields -> should NOT show row (no date-only row)
    XCTAssertFalse(macosTableSearchView.shouldDisplayRow(
      hasBodyContent: false,
      showDateHeader: true,
      hasDateValue: true,
      isBodyFiltered: true
    ))

    // 2. Body filtered, has body fields -> should show row
    XCTAssertTrue(macosTableSearchView.shouldDisplayRow(
      hasBodyContent: true,
      showDateHeader: true,
      hasDateValue: true,
      isBodyFiltered: true
    ))

    // 3. Body filtered, has body fields, date hidden -> should show row
    XCTAssertTrue(macosTableSearchView.shouldDisplayRow(
      hasBodyContent: true,
      showDateHeader: false,
      hasDateValue: false,
      isBodyFiltered: true
    ))

    // 4. Body unfiltered, has body fields -> should show row
    XCTAssertTrue(macosTableSearchView.shouldDisplayRow(
      hasBodyContent: true,
      showDateHeader: true,
      hasDateValue: true,
      isBodyFiltered: false
    ))

    // 5. Body unfiltered, has NO body fields but has date header & value -> should show row
    XCTAssertTrue(macosTableSearchView.shouldDisplayRow(
      hasBodyContent: false,
      showDateHeader: true,
      hasDateValue: true,
      isBodyFiltered: false
    ))

    // 6. Body unfiltered, has NO body fields and date header hidden -> should NOT show row
    XCTAssertFalse(macosTableSearchView.shouldDisplayRow(
      hasBodyContent: false,
      showDateHeader: false,
      hasDateValue: true,
      isBodyFiltered: false
    ))
  }

  func testDateFieldPickerSwitchSyncsRenderedObject() {
    let oldDateField = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    oldDateField.visible = true
    let newDateField = SquashedFieldsArray(squashedString: "@timestamp", fieldParts: ["@timestamp"])
    newDateField.visible = false

    var fields = [oldDateField, newDateField]
    var onlyVisible = [oldDateField, newDateField]
    var currentActive: String? = "timestamp"
    var rendered: RenderObject? = RenderObject(headers: [], results: [], flat: [], dateField: oldDateField)

    // Switch to newDateField
    let switched = macosSearchMainView.switchDateField(
      newDateField: newDateField,
      currentActiveDateField: &currentActive,
      fields: &fields,
      onlyVisibleFields: &onlyVisible,
      renderedObjects: &rendered
    )

    XCTAssertTrue(switched)
    XCTAssertEqual(currentActive, "@timestamp")
    XCTAssertFalse(oldDateField.visible)
    XCTAssertTrue(newDateField.visible)
    XCTAssertEqual(rendered?.dateField?.squashedString, "@timestamp")

    // Switching to same field returns false (no-op)
    let noOp = macosSearchMainView.switchDateField(
      newDateField: newDateField,
      currentActiveDateField: &currentActive,
      fields: &fields,
      onlyVisibleFields: &onlyVisible,
      renderedObjects: &rendered
    )
    XCTAssertFalse(noOp)

    // Switch to nil
    let switchedToNil = macosSearchMainView.switchDateField(
      newDateField: nil,
      currentActiveDateField: &currentActive,
      fields: &fields,
      onlyVisibleFields: &onlyVisible,
      renderedObjects: &rendered
    )
    XCTAssertTrue(switchedToNil)
    XCTAssertNil(currentActive)
    XCTAssertFalse(newDateField.visible)
    XCTAssertNil(rendered?.dateField)
  }

  func testSwitchDateFieldSetsVisibleOnPassedInstance() {
    let externalDateField = SquashedFieldsArray(squashedString: "created_at", fieldParts: ["created_at"])
    externalDateField.visible = false

    var fields = [externalDateField]
    var onlyVisible = [externalDateField]
    var currentActive: String? = nil
    var rendered: RenderObject? = nil

    let switched = macosSearchMainView.switchDateField(
      newDateField: externalDateField,
      currentActiveDateField: &currentActive,
      fields: &fields,
      onlyVisibleFields: &onlyVisible,
      renderedObjects: &rendered
    )

    XCTAssertTrue(switched)
    XCTAssertTrue(externalDateField.visible, "The passed newDateField instance must have visible set to true")
    XCTAssertEqual(currentActive, "created_at")
  }

  func testSwitchDateFieldNilToNilIsNoOp() {
    var fields = [SquashedFieldsArray]()
    var onlyVisible = [SquashedFieldsArray]()
    var currentActive: String? = nil
    var rendered: RenderObject? = nil

    let switched = macosSearchMainView.switchDateField(
      newDateField: nil,
      currentActiveDateField: &currentActive,
      fields: &fields,
      onlyVisibleFields: &onlyVisible,
      renderedObjects: &rendered
    )

    XCTAssertFalse(switched, "Switching nil to nil must be a no-op returning false")
    XCTAssertNil(currentActive)
  }

  func testMultipleDateFieldsTreatsSecondaryDateAsBodyField() {
    let primaryDateField = SquashedFieldsArray(squashedString: "@timestamp", fieldParts: ["@timestamp"])
    primaryDateField.type = "date"
    primaryDateField.visible = true

    let secondaryDateField = SquashedFieldsArray(squashedString: "event_time", fieldParts: ["event_time"])
    secondaryDateField.type = "date"
    secondaryDateField.visible = true

    let regularField = SquashedFieldsArray(squashedString: "message", fieldParts: ["message"])
    regularField.type = "text"
    regularField.visible = false

    let allFields = [primaryDateField, secondaryDateField, regularField]

    // Verify date header reflects only the primary active date field
    XCTAssertTrue(macosSearchMainView.shouldShowDateHeader(fields: allFields, activeDateField: primaryDateField))

    // Verify body filtered fields includes the secondary date field, but strips the primary date field
    let bodyFiltered = macosSearchMainView.computeBodyFilteredFields(fields: allFields, activeDateField: primaryDateField)
    XCTAssertEqual(bodyFiltered.count, 1)
    XCTAssertEqual(bodyFiltered[0].squashedString, "event_time")
    XCTAssertFalse(bodyFiltered.contains(where: { $0.squashedString == "@timestamp" }))
  }

  func testSelectAllFieldsIfFewSelectsEveryFieldBelowLimit() {
    let fields = (0..<9).map { SquashedFieldsArray(squashedString: "field\($0)", fieldParts: ["field\($0)"]) }
    let inDocument = SquashedFieldsArray(squashedString: "field3", fieldParts: ["field3"])
    let unmapped = SquashedFieldsArray(squashedString: "dynamic", fieldParts: ["dynamic"])

    let selected = macosSearchMainView.selectAllFieldsIfFew(fields: fields, onlyVisibleFields: [inDocument, unmapped])

    XCTAssertTrue(selected)
    XCTAssertTrue(fields.allSatisfy { $0.visible })
    XCTAssertTrue(inDocument.visible)
    XCTAssertFalse(unmapped.visible)
  }

  func testSelectAllFieldsIfFewLeavesTenOrMoreFieldsUnselected() {
    let fields = (0..<10).map { SquashedFieldsArray(squashedString: "field\($0)", fieldParts: ["field\($0)"]) }

    let selected = macosSearchMainView.selectAllFieldsIfFew(fields: fields, onlyVisibleFields: fields)

    XCTAssertFalse(selected)
    XCTAssertTrue(fields.allSatisfy { !$0.visible })
  }

  func testSelectAllFieldsIfFewIgnoresEmptyFields() {
    XCTAssertFalse(macosSearchMainView.selectAllFieldsIfFew(fields: [], onlyVisibleFields: []))
  }

  func testOrderSelectedFieldsFollowsDraggedOrder() {
    let fields = ["@timestamp", "env", "hostname", "level", "message"].map {
      SquashedFieldsArray(squashedString: $0, fieldParts: [$0])
    }
    func names(_ order: [String], pinned: String? = nil) -> [String] {
      macosSearchFieldSheetView.orderSelectedFields(fields, order: order, pinnedKey: pinned).map { $0.squashedString }
    }

    // No order yet keeps the mapped order
    XCTAssertEqual(names([]), ["@timestamp", "env", "hostname", "level", "message"])
    // Ordered keys come first; the rest keep their mapped order after them, and unknown keys are ignored
    XCTAssertEqual(names(["message", "gone", "env"]), ["message", "env", "@timestamp", "hostname", "level"])
    // The date field stays first wherever the order puts it
    XCTAssertEqual(names(["message", "@timestamp", "env"], pinned: "@timestamp"),
                   ["@timestamp", "message", "env", "hostname", "level"])
  }

  func testMoveFieldOntoAnotherRow() {
    let keys = ["env", "hostname", "level", "message"]
    // Dragging down lands after the target, dragging up lands before it
    XCTAssertEqual(macosSearchFieldSheetView.moveField("env", onto: "level", in: keys),
                   ["hostname", "level", "env", "message"])
    XCTAssertEqual(macosSearchFieldSheetView.moveField("message", onto: "hostname", in: keys),
                   ["env", "message", "hostname", "level"])
    XCTAssertEqual(macosSearchFieldSheetView.moveField("env", onto: "env", in: keys), keys)
    XCTAssertEqual(macosSearchFieldSheetView.moveField("missing", onto: "env", in: keys), keys)
  }

  func testSelectedModeAndColumnsUseFieldOrder() {
    let fields = ["@timestamp", "env", "hostname", "message"].map {
      SquashedFieldsArray(squashedString: $0, fieldParts: [$0])
    }
    fields.forEach { $0.visible = true }
    fields[2].visible = false
    let order = ["message", "env"]

    let listed = macosSearchFieldSheetView.filterFields(mode: .selected,
                                                        fields: fields,
                                                        onlyVisibleFields: [],
                                                        searchText: "",
                                                        fieldOrder: order,
                                                        dateFieldKey: "@timestamp")
    XCTAssertEqual(listed.map { $0.squashedString }, ["@timestamp", "message", "env"])

    let columns = macosSearchMainView.computeBodyFilteredFields(fields: fields,
                                                                activeDateField: fields[0],
                                                                order: order)
    XCTAssertEqual(columns.map { $0.squashedString }, ["message", "env"])
  }

  func testSidebarResizeMeasuresFromTheStartWidth() {
    // Dragging the left edge left widens the sidebar, right narrows it
    XCTAssertEqual(macosSearchMainView.resizedSidebarWidth(start: 300, translation: -50), 350)
    XCTAssertEqual(macosSearchMainView.resizedSidebarWidth(start: 300, translation: 80), 220)
    XCTAssertEqual(macosSearchMainView.resizedSidebarWidth(start: 300, translation: 0), 300)
  }

  func testSidebarResizeCapsAtTheMaximumAndHidesBelowTheMinimum() {
    XCTAssertEqual(macosSearchMainView.resizedSidebarWidth(start: 300, translation: -500), 600)
    XCTAssertEqual(macosSearchMainView.resizedSidebarWidth(start: 300, translation: 100), 200)
    XCTAssertNil(macosSearchMainView.resizedSidebarWidth(start: 300, translation: 101))
  }

  func testDocumentPanelResizeMeasuresFromTheStartWidth() {
    // Dragging the left edge left widens the panel, right narrows it
    XCTAssertEqual(macosSearchMainView.resizedDocumentPanelWidth(start: 500, translation: -100, available: 1200), 600)
    XCTAssertEqual(macosSearchMainView.resizedDocumentPanelWidth(start: 500, translation: 80, available: 1200), 420)
    XCTAssertEqual(macosSearchMainView.resizedDocumentPanelWidth(start: 500, translation: 0, available: 1200), 500)
  }

  func testDocumentPanelResizeStopsAtTheMinimumRatherThanClosing() {
    XCTAssertEqual(macosSearchMainView.resizedDocumentPanelWidth(start: 500, translation: 180, available: 1200), 320)
    XCTAssertEqual(macosSearchMainView.resizedDocumentPanelWidth(start: 500, translation: 900, available: 1200), 320)
  }

  func testDocumentPanelResizeLeavesRoomForTheResults() {
    XCTAssertEqual(macosSearchMainView.resizedDocumentPanelWidth(start: 500, translation: -500, available: 1200), 1000)
    XCTAssertEqual(macosSearchMainView.resizedDocumentPanelWidth(start: 500, translation: -501, available: 1200), 1000)
  }

  func testDocumentPanelWidthFollowsItsShareAndKeepsTheMinimumInANarrowArea() {
    XCTAssertEqual(macosSearchMainView.clampedDocumentPanelWidth(
      macosSearchMainView.defaultDocumentPanelFraction * 1200, available: 1200), 600)
    // Too narrow for both, so the panel keeps its minimum
    XCTAssertEqual(macosSearchMainView.clampedDocumentPanelWidth(250, available: 400), 320)
  }

  func testFieldColumnResizeMeasuresFromTheStartWidth() {
    // Dragging the divider right widens the Field column, left narrows it
    XCTAssertEqual(DocumentFieldsGrid.resizedFieldColumnWidth(start: 264, translation: 100, panelWidth: 800), 364)
    XCTAssertEqual(DocumentFieldsGrid.resizedFieldColumnWidth(start: 264, translation: -100, panelWidth: 800), 164)
    XCTAssertEqual(DocumentFieldsGrid.resizedFieldColumnWidth(start: 264, translation: 0, panelWidth: 800), 264)
  }

  func testFieldColumnResizeStopsAtTheMinimum() {
    XCTAssertEqual(DocumentFieldsGrid.resizedFieldColumnWidth(start: 264, translation: -124, panelWidth: 800), 140)
    XCTAssertEqual(DocumentFieldsGrid.resizedFieldColumnWidth(start: 264, translation: -500, panelWidth: 800), 140)
  }

  func testFieldColumnResizeLeavesRoomForTheValues() {
    // 600 less 30 padding, 16 spacing and a 120 Value column
    XCTAssertEqual(DocumentFieldsGrid.resizedFieldColumnWidth(start: 264, translation: 170, panelWidth: 600), 434)
    XCTAssertEqual(DocumentFieldsGrid.resizedFieldColumnWidth(start: 264, translation: 500, panelWidth: 600), 434)
  }

  func testFieldColumnKeepsItsMinimumInANarrowPanelAndItsWidthWhenWidenedAgain() {
    XCTAssertEqual(DocumentFieldsGrid.clampedFieldColumnWidth(264, panelWidth: 250), 140)
    XCTAssertEqual(DocumentFieldsGrid.clampedFieldColumnWidth(400, panelWidth: 400), 234)
    XCTAssertEqual(DocumentFieldsGrid.clampedFieldColumnWidth(400, panelWidth: 800), 400)
  }
#endif

  override func tearDown() {
    Request.mockedSession = nil
    searchRender = nil
    super.tearDown()
  }

  // MARK: - Where each result lives

  func testUpdateResultsKeepsRefsInOrder() {
    let refs: [DocumentRef?] = [DocumentRef(index: "logs-1", id: "a"), nil, DocumentRef(index: "logs-2", id: "c")]
    let rendered = Results.UpdateResults(searchResults: [["n": 1], ["n": 2], ["n": 3]],
                                         resultsFields: RenderedFields(fields: []),
                                         refs: refs)

    XCTAssertEqual(rendered?.ref(at: 0), DocumentRef(index: "logs-1", id: "a"))
    XCTAssertNil(rendered?.ref(at: 1))
    XCTAssertEqual(rendered?.ref(at: 2), DocumentRef(index: "logs-2", id: "c"))
  }

  func testRefOutsideTheResultsIsNil() {
    let withoutRefs = Results.UpdateResults(searchResults: [["n": 1]], resultsFields: RenderedFields(fields: []))
    XCTAssertNil(withoutRefs?.ref(at: 0))

    let rendered = RenderObject(headers: [], results: [], refs: [DocumentRef(index: "logs", id: "a")])
    XCTAssertNil(rendered.ref(at: -1))
    XCTAssertNil(rendered.ref(at: 1))
  }
}
