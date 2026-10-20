// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

// XCTest rather than Swift Testing: the mocked session is shared, so these mustn't run alongside other searches
@MainActor
final class DashboardPanelSearchTests: XCTestCase {

  var host: HostDetails!

  override func setUp() {
    super.setUp()
    host = HostDetails()
    host.host = HostURL()
    host.host?.url = "example.com"
    host.host?.port = "9200"
  }

  override func tearDown() {
    Request.mockedSession = nil
    super.tearDown()
  }

  let response = """
  {
    "hits": {
      "total": { "value": 1234, "relation": "gte" },
      "hits": [
        { "_index": "logs-1", "_id": "a", "_source": { "@timestamp": "2026-10-20T09:15:00Z", "status": 500, "host": { "name": "web-1" } } },
        { "_index": "logs-1", "_id": "b", "_source": { "@timestamp": "2026-10-20T09:14:00Z", "status": 404 } }
      ]
    }
  }
  """

  private func search(selectedFields: [String]) -> SavedSearch {
    SavedSearch(hostId: UUID(),
                searchIndex: "logs-*",
                dateField: SavedDateField(field: "@timestamp", type: "date"),
                period: .relative(value: 1, period: .Hours),
                query: "status:>400",
                selectedFields: selectedFields)
  }

  func testRunAsksForTheRowLimitAndShowsTheSavedColumns() async throws {
    let session = CapturingURLSession(body: response)
    Request.mockedSession = session

    let result = await DashboardPanelSearch.run(search(selectedFields: ["host.name", "status"]),
                                                host: host, dataView: nil, rowLimit: 5)

    XCTAssertNil(result.error)
    XCTAssertEqual(result.columns, [.date("@timestamp"), .field("host.name"), .field("status")])
    XCTAssertEqual(result.rows.map { Array($0.cells.dropFirst()) }, [["web-1", "500"], [nil, "404"]])
    XCTAssertEqual(result.hits, 1234)
    XCTAssertTrue(result.hitsIsLowerBound)
    XCTAssertNotNil(result.duration)

    let request = try XCTUnwrap(session.lastRequest)
    XCTAssertTrue(request.url?.path.hasPrefix("/logs-*/_search") ?? false)
    let body = try XCTUnwrap(request.httpBody.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: Any] })
    XCTAssertEqual(body["size"] as? Int, 5)
    XCTAssertEqual(body["from"] as? Int, 0)
  }

  func testASearchWithoutColumnsShowsEachDocumentAsASummary() async {
    Request.mockedSession = CapturingURLSession(body: response)

    let result = await DashboardPanelSearch.run(search(selectedFields: []), host: host, dataView: nil, rowLimit: 10)

    XCTAssertEqual(result.columns, [.date("@timestamp"), .document])
    XCTAssertEqual(result.rows.last?.cells.last, "status: 404")
  }

  func testAServerErrorIsShownWithoutRows() async {
    Request.mockedSession = MockURLSession(response: """
    { "error": { "root_cause": [ { "type": "index_not_found_exception", "reason": "no such index [logs-*]" } ] }, "status": 404 }
    """, status: 404)

    let result = await DashboardPanelSearch.run(search(selectedFields: ["status"]), host: host, dataView: nil, rowLimit: 10)

    XCTAssertEqual(result.error?.message, "no such index [logs-*]")
    XCTAssertTrue(result.rows.isEmpty)
    XCTAssertTrue(result.columns.isEmpty)
  }
}
