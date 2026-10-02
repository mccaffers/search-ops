// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

// CapturingURLSession is shared with AWSSigV4SignerTests
@available(iOS 16.0.0, *)
final class DevConsoleTests: XCTestCase {

  private func makeHost() -> HostDetails {
    let host = HostDetails()
    host.host?.url = "localhost"
    host.host?.port = "9200"
    host.host?.scheme = .HTTP
    return host
  }

  private func parse(_ input: String) throws -> DevConsoleRequest {
    try DevConsoleParser.parse(input).get()
  }

  // MARK: Parser

  func testParseSimpleGet() throws {
    let request = try parse("GET /_cluster/health")
    XCTAssertEqual(request, DevConsoleRequest(method: .GET, path: "/_cluster/health"))
    XCTAssertEqual(request.sentMethod, .GET)
  }

  func testParseLowercaseMethodAndMissingSlash() throws {
    let request = try parse("  get _cat/indices?v  ")
    XCTAssertEqual(request.method, .GET)
    XCTAssertEqual(request.path, "/_cat/indices?v")
  }

  func testParseSkipsLeadingBlankLines() throws {
    let request = try parse("\n\n   \nPOST /idx/_count\n{\"query\":{\"match_all\":{}}}")
    XCTAssertEqual(request.method, .POST)
    XCTAssertEqual(request.path, "/idx/_count")
    XCTAssertEqual(request.body, "{\"query\":{\"match_all\":{}}}")
  }

  func testGetWithBodyIsSentAsPost() throws {
    let request = try parse("GET /idx/_search\n{\n  \"size\": 1\n}\n")
    XCTAssertEqual(request.method, .GET)
    XCTAssertEqual(request.body, "{\n  \"size\": 1\n}")
    XCTAssertEqual(request.sentMethod, .POST)
  }

  func testParseEmpty() {
    XCTAssertEqual(DevConsoleParser.parse("  \n \n"), .failure(.empty))
  }

  func testParseUnsupportedMethod() {
    XCTAssertEqual(DevConsoleParser.parse("DELETE /idx"), .failure(.unsupportedMethod("DELETE")))
  }

  func testParseMissingPath() {
    XCTAssertEqual(DevConsoleParser.parse("GET"), .failure(.missingPath))
  }

  func testParseTooManyTokensOnRequestLine() {
    XCTAssertEqual(DevConsoleParser.parse("GET /idx extra"), .failure(.invalidPath("GET /idx extra")))
  }

  func testParseInvalidJSONBody() {
    guard case .failure(.invalidJSON(let message)) = DevConsoleParser.parse("POST /idx/_search\n{ \"size\": }") else {
      return XCTFail("Expected invalid JSON")
    }
    XCTAssertFalse(message.isEmpty)
  }

  func testInvalidJSONErrorUsesEditorLineNumbers() {
    // The bad value is on editor line 3, which is line 2 of the body
    guard case .failure(.invalidJSON(let message)) = DevConsoleParser.parse("POST /idx/_search\n{\n  \"size\": ,\n}") else {
      return XCTFail("Expected invalid JSON")
    }
    XCTAssertTrue(message.contains("line 3"), message)
  }

  func testInvalidJSONLineNumbersCountBlankLinesBeforeBody() {
    // Editor lines: 1 blank, 2 request, 3 blank, 4 "{", 5 bad value
    guard case .failure(.invalidJSON(let message)) = DevConsoleParser.parse("\nPOST /idx/_search\n\n{\n  \"size\": ,\n}") else {
      return XCTFail("Expected invalid JSON")
    }
    XCTAssertTrue(message.contains("line 5"), message)
  }

  func testShiftLineNumbers() {
    XCTAssertEqual(DevConsoleParser.shiftLineNumbers(in: "Invalid value around line 2, column 10.", by: 1),
                   "Invalid value around line 3, column 10.")
    XCTAssertEqual(DevConsoleParser.shiftLineNumbers(in: "Invalid value around line 2, column 10.", by: 0),
                   "Invalid value around line 2, column 10.")
    XCTAssertEqual(DevConsoleParser.shiftLineNumbers(in: "No line number here", by: 3),
                   "No line number here")
  }

  func testBodyKeepsLeadingIndentOnFirstLine() throws {
    // Keeping it means JSON error columns match the editor
    let request = try parse("POST /idx/_count\n  {\"size\": 1}  \n\n")
    XCTAssertEqual(request.body, "  {\"size\": 1}")
  }

  func testParseNDJSONBodyAddsTrailingNewline() throws {
    let input = """
    POST /_bulk
    { "index": { "_index": "test", "_id": "1" } }
    { "field": "value" }
    """
    let request = try parse(input)
    XCTAssertEqual(request.body,
                   "{ \"index\": { \"_index\": \"test\", \"_id\": \"1\" } }\n{ \"field\": \"value\" }\n")
  }

  // MARK: Formatting

  func testReindentPreservesKeyOrder() {
    let output = DevConsoleService.reindentJSON("{\"took\":3,\"hits\":{\"total\":1,\"hits\":[]},\"a\":{}}")
    XCTAssertEqual(output, """
    {
      "took": 3,
      "hits": {
        "total": 1,
        "hits": []
      },
      "a": {}
    }
    """)
  }

  func testReindentLeavesStringContentsAlone() {
    let output = DevConsoleService.reindentJSON("{\"q\":\"a, {b} : [c] \\\" d\"}")
    XCTAssertEqual(output, "{\n  \"q\": \"a, {b} : [c] \\\" d\"\n}")
  }

  func testFormatBodyNonJSONReturnedAsIs() {
    let catOutput = "green open idx abc 1 0 10 0 1kb 1kb\n"
    let formatted = DevConsoleService.formatBody(Data(catOutput.utf8))
    XCTAssertFalse(formatted.isJSON)
    XCTAssertEqual(formatted.text, catOutput)
  }

  // MARK: Sending

  @MainActor
  func testSendGetWithBodyUsesPostAndFormatsResponse() async throws {
    let session = CapturingURLSession(body: "{\"took\":1,\"hits\":{\"hits\":[]}}", status: 200)
    Request.mockedSession = session

    let request = try parse("GET /idx/_search\n{\"size\":1}")
    let result = await DevConsoleService.send(host: makeHost(), request: request)

    XCTAssertEqual(session.lastRequest?.httpMethod, "POST")
    XCTAssertEqual(session.lastRequest?.url?.absoluteString, "http://localhost:9200/idx/_search")
    XCTAssertEqual(session.lastRequest?.httpBody, Data("{\"size\":1}".utf8))

    XCTAssertEqual(result.status, 200)
    XCTAssertEqual(result.sentMethod, .POST)
    XCTAssertTrue(result.isJSON)
    XCTAssertNil(result.errorMessage)
    XCTAssertNotNil(result.duration)
    XCTAssertEqual(result.body, "{\n  \"took\": 1,\n  \"hits\": {\n    \"hits\": []\n  }\n}")
  }

  @MainActor
  func testSendReturnsErrorStatusBody() async throws {
    Request.mockedSession = CapturingURLSession(body: "{\"error\":\"index_not_found\"}", status: 404)

    let result = await DevConsoleService.send(host: makeHost(), request: try parse("GET /missing"))

    XCTAssertEqual(result.status, 404)
    XCTAssertNil(result.errorMessage)
    XCTAssertTrue(result.body.contains("index_not_found"))
  }

  @MainActor
  func testSendNetworkFailure() async throws {
    Request.mockedSession = MockURLSession(response: "", exception: true)

    let result = await DevConsoleService.send(host: makeHost(), request: try parse("GET /"))

    XCTAssertEqual(result.status, 0)
    XCTAssertNotNil(result.errorMessage)
    XCTAssertEqual(result.body, "")
  }

  func testCancelledResultKeepsSentMethodAndPath() throws {
    let result = DevConsoleResult.cancelled(try parse("GET /idx/_search\n{\"size\":1}"))

    XCTAssertTrue(result.isCancelled)
    XCTAssertEqual(result.status, 0)
    XCTAssertEqual(result.sentMethod, .POST)
    XCTAssertEqual(result.path, "/idx/_search")
    XCTAssertEqual(result.errorMessage, "Request cancelled")
    XCTAssertNil(result.duration)
    XCTAssertEqual(result.body, "")
  }

  // MARK: Headers

  @MainActor
  func testCustomHeadersAreSentWithNameAndValue() async {
    let session = CapturingURLSession()
    Request.mockedSession = session

    let host = makeHost()
    let header = Headers()
    header.header = "X-Test"
    header.value = "123"
    host.customHeaders.append(header)

    _ = await Request().invoke(serverDetails: host, endpoint: "/")

    XCTAssertEqual(session.lastRequest?.value(forHTTPHeaderField: "X-Test"), "123")
  }

  @MainActor
  func testApiKeyAddsKibanaXsrfHeader() async {
    let session = CapturingURLSession()
    Request.mockedSession = session

    let host = makeHost()
    host.apiKey = "abc"

    _ = await Request().invoke(serverDetails: host, endpoint: "/")

    XCTAssertEqual(session.lastRequest?.value(forHTTPHeaderField: "Authorization"), "ApiKey abc")
    XCTAssertEqual(session.lastRequest?.value(forHTTPHeaderField: "kbn-xsrf"), "true")
  }
}
