// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import Foundation
import RealmSwift

@testable import Search_Ops

@available(macOS 13.0, *)
@available(iOS 16.0, *)
final class LogDataManagerTests: XCTestCase {

  @MainActor
  override func setUp() {
    super.setUp()
    _ = RealmManager().getRealm(inMemory: true)
    LogDataManager().deleteAll()
  }

  private func makeHost() -> HostDetails {
    let host = HostDetails()
    host.name = "Local"
    host.env = "Dev"
    host.host?.url = "localhost"
    host.host?.port = "9200"
    host.host?.scheme = .HTTP
    return host
  }

  private func makeResponse(path: String, body: String = "{}", status: Int = 200) -> ServerResponse {
    let response = ServerResponse()
    response.url = URL(string: "http://localhost:9200" + path)
    response.method = "POST"
    response.httpStatus = status
    response.parsed = body
    response.duration = .milliseconds(42)
    return response
  }

  @MainActor
  private func makeEvent(path: String, date: Date) -> LogEvent {
    let event = LogEvent()
    event.date = date
    event.host = LogHostDetails()
    event.host?.host = HostURL()
    event.host?.host?.path = path
    return event
  }

  @MainActor
  private func realm() throws -> Realm {
    try XCTUnwrap(RealmManager().getRealm())
  }

  // MARK: Rotation

  @MainActor
  func testKeepsOnlyTheNewestFiftyEvents() throws {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    for number in 0..<60 {
      LogDataManager().addNew(item: makeEvent(path: "/request-\(number)",
                                              date: start.addingTimeInterval(Double(number))))
    }

    let entries = LogDataManager().newestFirst
    XCTAssertEqual(LogDataManager.limit, 50)
    XCTAssertEqual(entries.count, 50)
    XCTAssertEqual(entries.first?.displayPath, "/request-59")
    XCTAssertEqual(entries.last?.displayPath, "/request-10")

    // The deleted events' host details go with them
    XCTAssertEqual(try realm().objects(LogHostDetails.self).count, 50)
  }

  @MainActor
  func testDeleteAllRemovesEventsAndTheirHosts() throws {
    Logger.event(response: makeResponse(path: "/idx/_search"), host: makeHost())
    Logger.event(response: makeResponse(path: "/idx/_mapping"), host: makeHost())
    XCTAssertEqual(LogDataManager().newestFirst.count, 2)

    let manager = LogDataManager()
    manager.deleteAll()

    XCTAssertTrue(manager.items.isEmpty)
    XCTAssertTrue(LogDataManager().newestFirst.isEmpty)
    XCTAssertEqual(try realm().objects(LogHostDetails.self).count, 0)
  }

  // MARK: Logger

  @MainActor
  func testLoggerStoresPageHitCountAndSource() throws {
    Logger.event(response: makeResponse(path: "/idx/_search"),
                 index: "idx",
                 host: makeHost(),
                 page: 3,
                 hitCount: 1234,
                 source: LogEvent.devConsoleSource)

    let event = try XCTUnwrap(LogDataManager().newestFirst.first)
    XCTAssertEqual(event.page, 3)
    XCTAssertEqual(event.hitCount, 1234)
    XCTAssertEqual(event.source, "Dev Console")
    XCTAssertEqual(event.index, "idx")
    XCTAssertEqual(event.method, "POST")
    XCTAssertEqual(event.httpStatus, 200)
    XCTAssertEqual(event.host?.name, "Local")
    XCTAssertEqual(event.displayPath, "/idx/_search")
    XCTAssertFalse(event.jsonResTruncated)
  }

  @MainActor
  func testLoggerCapsLargeBodies() throws {
    let response = makeResponse(path: "/idx/_search",
                                body: String(repeating: "a", count: LogEvent.bodyLimit + 10))
    response.jsonReq = "{\"size\":1}"
    Logger.event(response: response, host: makeHost())

    let event = try XCTUnwrap(LogDataManager().newestFirst.first)
    XCTAssertTrue(event.jsonResTruncated)
    XCTAssertEqual(event.jsonRes.utf8.count, LogEvent.bodyLimit)
    XCTAssertFalse(event.jsonReqTruncated)
    XCTAssertEqual(event.jsonReq, "{\"size\":1}")
  }

  func testCappedKeepsShortBodiesWhole() {
    let capped = LogEvent.capped("{\"took\":1}", limit: 100)
    XCTAssertEqual(capped.text, "{\"took\":1}")
    XCTAssertFalse(capped.truncated)
  }

  func testCappedDoesNotSplitACharacter() {
    // "aébé" is 6 bytes, "é" takes 2, so a limit that ends halfway through an "é" stops before it
    XCTAssertEqual(LogEvent.capped("aébé", limit: 5).text, "aéb")
    XCTAssertEqual(LogEvent.capped("aébé", limit: 4).text, "aéb")
    XCTAssertEqual(LogEvent.capped("aébé", limit: 3).text, "aé")
    XCTAssertEqual(LogEvent.capped("aébé", limit: 2).text, "a")
    XCTAssertTrue(LogEvent.capped("aébé", limit: 2).truncated)
  }

  // MARK: Display

  @MainActor
  func testDisplayPathAndResultSummary() {
    let connectionTest = makeEvent(path: "", date: .now)
    XCTAssertEqual(connectionTest.displayPath, "Connection Test")
    XCTAssertNil(connectionTest.resultSummary)

    let consoleRoot = makeEvent(path: "", date: .now)
    consoleRoot.source = LogEvent.devConsoleSource
    XCTAssertEqual(consoleRoot.displayPath, "/")

    let search = makeEvent(path: "/idx/_search", date: .now)
    search.hitCount = 12
    XCTAssertEqual(search.resultSummary, "12 docs · page 1")
    search.page = 2
    XCTAssertEqual(search.resultSummary, "12 docs · page 2")

    let mapping = makeEvent(path: "idx/_mapping", date: .now)
    mapping.hitCount = 34
    XCTAssertEqual(mapping.displayPath, "/idx/_mapping")
    XCTAssertEqual(mapping.resultSummary, "34 fields")

    // Dev Console responses aren't read, so there's no count to show
    let consoleSearch = makeEvent(path: "/idx/_search", date: .now)
    consoleSearch.source = LogEvent.devConsoleSource
    XCTAssertNil(consoleSearch.resultSummary)
  }

  // MARK: Dev Console

  @MainActor
  func testDevConsoleRequestsAreLogged() async throws {
    Request.mockedSession = CapturingURLSession(body: "{\"took\":1}", status: 200)
    defer { Request.mockedSession = nil }

    let request = try DevConsoleParser.parse("GET /idx/_search\n{\"size\":1}").get()
    _ = await DevConsoleService.send(host: makeHost(), request: request)

    let event = try XCTUnwrap(LogDataManager().newestFirst.first)
    XCTAssertEqual(event.source, LogEvent.devConsoleSource)
    XCTAssertEqual(event.method, "POST")
    XCTAssertEqual(event.displayPath, "/idx/_search")
    XCTAssertEqual(event.httpStatus, 200)
    XCTAssertEqual(event.jsonReq, "{\"size\":1}")
    XCTAssertEqual(event.jsonRes, "{\"took\":1}")
    XCTAssertFalse(event.duration.isEmpty)
  }

  @MainActor
  func testDevConsoleTemplateMappingIsLogged() async throws {
    let mapping = "{\"idx\":{\"mappings\":{\"properties\":{\"title\":{\"type\":\"text\"},\"count\":{\"type\":\"long\"}}}}}"
    Request.mockedSession = CapturingURLSession(body: mapping, status: 200)
    defer { Request.mockedSession = nil }

    _ = await DevConsoleTemplateService.loadFields(host: makeHost(), index: "idx")

    let event = try XCTUnwrap(LogDataManager().newestFirst.first)
    XCTAssertEqual(event.source, LogEvent.devConsoleSource)
    XCTAssertEqual(event.method, "GET")
    XCTAssertEqual(event.displayPath, "/idx/_mapping")
    XCTAssertEqual(event.index, "idx")
    XCTAssertGreaterThan(event.hitCount, 0)
  }
}
