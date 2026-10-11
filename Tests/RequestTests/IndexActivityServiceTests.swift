// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

@available(iOS 16.0.0, *)
final class IndexActivityServiceTests: XCTestCase {

  /// Answers each request from `route` and keeps every request it was sent. A status of 0 throws,
  /// as a timeout does. Requests arrive from several tasks at once, so the list is locked
  final class RoutingURLSession: URLSessionProtocol {
    private let lock = NSLock()
    private var sent = [URLRequest]()
    let route: (URLRequest) -> (status: Int, body: String)

    init(route: @escaping (URLRequest) -> (status: Int, body: String)) {
      self.route = route
    }

    var requests: [URLRequest] {
      lock.withLock { sent }
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
      lock.withLock { sent.append(request) }
      let answer = route(request)
      if answer.status == 0 { throw URLError(.timedOut) }
      let response = HTTPURLResponse(url: request.url!, statusCode: answer.status, httpVersion: nil, headerFields: nil)!
      return (Data(answer.body.utf8), response)
    }
  }

  override func setUp() async throws {
    try await super.setUp()
    await MainActor.run { IndexActivityService.clearDateFieldCache() }
  }

  override func tearDown() async throws {
    Request.mockedSession = nil
    await MainActor.run { IndexActivityService.clearDateFieldCache() }
    try await super.tearDown()
  }

  private func makeHost() -> HostDetails {
    let host = HostDetails()
    host.host?.url = "localhost"
    host.host?.port = "9200"
    host.host?.scheme = .HTTP
    return host
  }

  // MARK: Helpers for routing

  static func isMapping(_ request: URLRequest) -> Bool {
    request.url?.path.hasSuffix("/_mapping") ?? false
  }

  static func isSearch(_ request: URLRequest) -> Bool {
    request.url?.path.hasSuffix("/_search") ?? false
  }

  /// The indices named in the path, eg. a,b from /a,b/_search
  static func indices(in request: URLRequest) -> [String] {
    let parts = (request.url?.path ?? "").split(separator: "/")
    return parts.count == 2 ? parts[0].split(separator: ",").map(String.init) : []
  }

  static func mapping(for indices: [String]) -> String {
    let entries = indices.map { #""\#($0)":{"mappings":{"properties":{"@timestamp":{"type":"date"}}}}"# }
    return "{" + entries.joined(separator: ",") + "}"
  }

  /// A batched or single index answer, `timestamps` keyed by index
  static func searchAnswer(_ request: URLRequest, timestamps: [String: Double]) -> String {
    let body = request.httpBody.map { String(decoding: $0, as: UTF8.self) } ?? ""
    let names = indices(in: request)
    if body.contains("by_index") {
      let buckets = names.compactMap { name in
        timestamps[name].map { #"{"key":"\#(name)","doc_count":1,"max_date":{"value":\#($0)}}"# }
      }
      return #"{"aggregations":{"by_index":{"buckets":["# + buckets.joined(separator: ",") + "]}}}"
    }
    let value = names.first.flatMap { timestamps[$0] }.map { "\($0)" } ?? "null"
    return #"{"aggregations":{"max_date":{"value":\#(value)}}}"#
  }

  // MARK: Batching

  func testChunksStayUnderTheByteBudgetInOrder() {
    let names = (0..<500).map { String(format: ".ds-logs-app-default-2026.10.%03d-000001", $0) }
    let chunks = IndexActivityService.chunk(names, maxBytes: 3_000)

    XCTAssertGreaterThan(chunks.count, 1)
    XCTAssertEqual(chunks.flatMap { $0 }, names)
    for chunk in chunks {
      XCTAssertLessThanOrEqual(chunk.joined(separator: ",").utf8.count, 3_000)
    }
  }

  func testChunkGivesALongNameItsOwnList() {
    let long = String(repeating: "a", count: 40)
    XCTAssertEqual(IndexActivityService.chunk(["a", long, "b"], maxBytes: 10), [["a"], [long], ["b"]])
    XCTAssertEqual(IndexActivityService.chunk(["a", "b", "c"], maxBytes: 3), [["a", "b"], ["c"]])
    XCTAssertEqual(IndexActivityService.chunk([], maxBytes: 3), [])
  }

  func testMappingEndpointsAreScopedWhenFewIndices() {
    let endpoints = IndexActivityService.mappingEndpoints(for: ["logs", "metrics"])
    XCTAssertEqual(endpoints, ["/logs,metrics/_mapping?ignore_unavailable=true&filter_path=*.mappings.**.type,*.mappings.**.format"])

    let unfiltered = IndexActivityService.mappingEndpoints(for: ["logs", "metrics"], filtered: false)
    XCTAssertEqual(unfiltered, ["/logs,metrics/_mapping?ignore_unavailable=true"])
  }

  func testMappingEndpointsCoverTheClusterWhenManyIndices() {
    let names = (0..<2_000).map { "logs-app-\($0)" }
    let endpoints = IndexActivityService.mappingEndpoints(for: names)
    XCTAssertEqual(endpoints, ["/_mapping?expand_wildcards=all&filter_path=*.mappings.**.type,*.mappings.**.format"])
  }

  func testFilteredMappingIsParsed() {
    // What filter_path leaves of a mapping: only the type and format keys, and the objects around them
    let filtered = """
    {"logs":{"mappings":{"properties":{
      "message":{"type":"text","fields":{"keyword":{"type":"keyword"}}},
      "event":{"properties":{"created":{"type":"date","format":"epoch_second"}}},
      "seen":{"type":"text","fields":{"at":{"type":"date_nanos"}}}
    }}}}
    """
    let parsed = IndexActivityService.parseDateFieldsByIndices(from: Data(filtered.utf8), targetIndices: ["logs"])
    XCTAssertEqual(Set(parsed["logs"] ?? []), [
      DateFieldInfo(name: "event.created", isNanos: false, isSeconds: true),
      DateFieldInfo(name: "seen.at", isNanos: true)
    ])
  }

  // MARK: Fetching

  @MainActor
  func testFetchUsesOneFilteredMappingAndOneSearch() async {
    let session = RoutingURLSession { request in
      if Self.isMapping(request) { return (200, Self.mapping(for: Self.indices(in: request))) }
      return (200, Self.searchAnswer(request, timestamps: ["old": 1_000, "new": 2_000]))
    }
    Request.mockedSession = session

    let result = await IndexActivityService.fetchIndicesActivity(serverDetails: makeHost(), indices: ["old", "new"])

    XCTAssertEqual(result.sortedIndices, ["new", "old"])
    XCTAssertNil(result.errorMessage)
    let requests = session.requests
    XCTAssertEqual(requests.count, 2)
    XCTAssertEqual(requests.first?.url?.path, "/old,new/_mapping")
    XCTAssertTrue(requests.first?.url?.query?.contains("filter_path=") ?? false)
    XCTAssertEqual(requests.last?.url?.path, "/old,new/_search")
    XCTAssertEqual(requests.last?.url?.query, "ignore_unavailable=true")
  }

  @MainActor
  func testIndicesWithoutDocumentsDontFallBackToOneRequestEach() async {
    let session = RoutingURLSession { request in
      if Self.isMapping(request) { return (200, Self.mapping(for: Self.indices(in: request))) }
      return (200, Self.searchAnswer(request, timestamps: [:]))
    }
    Request.mockedSession = session

    let result = await IndexActivityService.fetchIndicesActivity(serverDetails: makeHost(), indices: ["a", "b", "c"])

    XCTAssertEqual(session.requests.count, 2, "Empty buckets are an answer, not a failure")
    XCTAssertEqual(result.errorMessage, "No document activity found in indices")
  }

  @MainActor
  func testFailedBatchIsSplitInHalves() async {
    let names = (1...8).map { "idx-\($0)" }
    var timestamps: [String: Double] = [:]
    for (offset, name) in names.enumerated() where name != "idx-6" {
      timestamps[name] = Double(offset + 1) * 1_000
    }
    let session = RoutingURLSession { request in
      if Self.isMapping(request) { return (200, Self.mapping(for: Self.indices(in: request))) }
      // idx-6 fails any search it's part of
      if Self.indices(in: request).contains("idx-6") {
        return (400, #"{"error":{"type":"illegal_argument_exception","reason":"bad field"},"status":400}"#)
      }
      return (200, Self.searchAnswer(request, timestamps: timestamps))
    }
    Request.mockedSession = session

    let result = await IndexActivityService.fetchIndicesActivity(serverDetails: makeHost(), indices: names)

    XCTAssertEqual(result.timestamps, timestamps)
    XCTAssertEqual(result.sortedIndices.last, "idx-6")
    // All 8, then 4 + 4, then 2 + 2, then 1 + 1: 7 rather than 1 + 8 one at a time
    XCTAssertEqual(session.requests.filter(Self.isSearch).count, 7)
  }

  @MainActor
  func testUnusableClusterIsNotSplit() async {
    let names = (1...8).map { "idx-\($0)" }
    for status in [401, 403, 429, 500, 503] {
      IndexActivityService.clearDateFieldCache()
      let session = RoutingURLSession { request in
        if Self.isMapping(request) { return (200, Self.mapping(for: Self.indices(in: request))) }
        return (status, #"{"error":"no"}"#)
      }
      Request.mockedSession = session

      let result = await IndexActivityService.fetchIndicesActivity(serverDetails: makeHost(), indices: names)

      XCTAssertEqual(session.requests.filter(Self.isSearch).count, 1, "HTTP \(status) fails every request")
      XCTAssertEqual(result.errorMessage, "Failed to fetch index activity (HTTP \(status))")
      XCTAssertEqual(result.sortedIndices, names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }
  }

  @MainActor
  func testConnectionErrorIsNotSplit() async {
    let session = RoutingURLSession { request in
      if Self.isMapping(request) { return (200, Self.mapping(for: Self.indices(in: request))) }
      return (0, "")
    }
    Request.mockedSession = session

    let result = await IndexActivityService.fetchIndicesActivity(serverDetails: makeHost(),
                                                                 indices: (1...8).map { "idx-\($0)" })

    XCTAssertEqual(session.requests.filter(Self.isSearch).count, 1)
    XCTAssertEqual(result.errorMessage, URLError(.timedOut).localizedDescription)
  }

  @MainActor
  func testFatalFailureWhileSplittingStops() async {
    let names = (1...8).map { "idx-\($0)" }
    let session = RoutingURLSession { request in
      if Self.isMapping(request) { return (200, Self.mapping(for: Self.indices(in: request))) }
      // The whole batch is a bad query, then the cluster goes down
      if Self.indices(in: request).count == names.count {
        return (400, #"{"error":{"type":"illegal_argument_exception","reason":"bad field"},"status":400}"#)
      }
      return (503, #"{"error":"unavailable"}"#)
    }
    Request.mockedSession = session

    let result = await IndexActivityService.fetchIndicesActivity(serverDetails: makeHost(), indices: names)

    // All 8, then the first 4, then stop: not 15
    XCTAssertEqual(session.requests.filter(Self.isSearch).count, 2)
    XCTAssertEqual(result.errorMessage, "Failed to fetch index activity (HTTP 503)")
  }

  @MainActor
  func testFatalFailureStopsQueuedBatches() async {
    // Each name fills most of a batch, so every index is a batch of its own
    let names = (1...(IndexActivityService.maxConcurrentSearches + 4)).map {
      "idx-\($0)-" + String(repeating: "x", count: IndexActivityService.maxIndexPathBytes / 2)
    }
    XCTAssertEqual(IndexActivityService.chunk(names).count, names.count)
    let session = RoutingURLSession { request in
      // So many batches fetch the whole cluster's mappings
      if Self.isMapping(request) { return (200, Self.mapping(for: names)) }
      return (401, #"{"error":"unauthorized"}"#)
    }
    Request.mockedSession = session

    let result = await IndexActivityService.fetchIndicesActivity(serverDetails: makeHost(), indices: names)

    // Only the batches already in flight, none started after the first 401
    XCTAssertEqual(session.requests.filter(Self.isSearch).count, IndexActivityService.maxConcurrentSearches)
    XCTAssertEqual(result.errorMessage, "Failed to fetch index activity (HTTP 401)")
  }

  @MainActor
  func testMappingsAreCachedForTheHost() async {
    let session = RoutingURLSession { request in
      if Self.isMapping(request) { return (200, Self.mapping(for: Self.indices(in: request))) }
      return (200, Self.searchAnswer(request, timestamps: ["a": 1_000, "b": 2_000, "c": 3_000]))
    }
    Request.mockedSession = session
    let host = makeHost()

    _ = await IndexActivityService.fetchIndicesActivity(serverDetails: host, indices: ["a", "b"])
    // Only the new index's mapping is fetched
    let result = await IndexActivityService.fetchIndicesActivity(serverDetails: host, indices: ["a", "b", "c"])

    XCTAssertEqual(result.sortedIndices, ["c", "b", "a"])
    let mappings = session.requests.filter(Self.isMapping).compactMap { $0.url?.path }
    XCTAssertEqual(mappings, ["/a,b/_mapping", "/c/_mapping"])
  }

  func testDetachedCopySharesItsHostsCache() {
    let host = makeHost()
    host.id = UUID()
    XCTAssertEqual(IndexActivityService.cacheKey(for: host.generateCopy()), host.id)
  }

  @MainActor
  func testCacheExpires() async {
    let session = RoutingURLSession { request in
      if Self.isMapping(request) { return (200, Self.mapping(for: Self.indices(in: request))) }
      return (200, Self.searchAnswer(request, timestamps: ["a": 1_000]))
    }
    Request.mockedSession = session
    let host = makeHost()

    _ = await IndexActivityService.fetchIndicesActivity(serverDetails: host, indices: ["a"])
    // Age the entry past its lifetime
    let key = IndexActivityService.cacheKey(for: host)
    let entry = IndexActivityService.dateFieldCache[key]?["a"]
    IndexActivityService.dateFieldCache[key]?["a"] = IndexActivityService.CachedDateField(
      field: entry?.field,
      fetched: Date().addingTimeInterval(-IndexActivityService.dateFieldCacheLifetime - 1))
    _ = await IndexActivityService.fetchIndicesActivity(serverDetails: host, indices: ["a"])

    XCTAssertEqual(session.requests.filter(Self.isMapping).count, 2)
  }

  @MainActor
  func testRejectedFilterPathIsRetriedWithoutIt() async {
    let session = RoutingURLSession { request in
      if Self.isMapping(request) {
        if request.url?.query?.contains("filter_path") ?? false {
          return (400, #"{"error":"filter_path not supported"}"#)
        }
        return (200, Self.mapping(for: Self.indices(in: request)))
      }
      return (200, Self.searchAnswer(request, timestamps: ["a": 1_000]))
    }
    Request.mockedSession = session

    let result = await IndexActivityService.fetchIndicesActivity(serverDetails: makeHost(), indices: ["a"])

    XCTAssertEqual(result.timestamps, ["a": 1_000])
    XCTAssertEqual(session.requests.filter(Self.isMapping).count, 2)
  }

  @MainActor
  func testMappingFailureIsReported() async {
    Request.mockedSession = RoutingURLSession { _ in (500, #"{"error":"boom"}"#) }

    let result = await IndexActivityService.fetchIndicesActivity(serverDetails: makeHost(), indices: ["b", "a"])

    XCTAssertEqual(result.errorMessage, "Failed to fetch index mappings (HTTP 500)")
    XCTAssertEqual(result.sortedIndices, ["a", "b"])
  }
}
