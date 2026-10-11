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

  // MARK: Read only

  func testReadOnlyAllowsReadsAndMaintenance() throws {
    let allowed = [
      "GET /_cat/indices?v",
      "GET /_cluster/health",
      "GET /idx/_search\n{\"size\":1}",
      "POST /idx/_search",
      "POST /_search?scroll=1m",
      "POST /logs-*,metrics/_search\n{}",
      "POST /_all/_search",
      "POST _search/scroll\n{\"scroll_id\":\"abc\"}",
      "POST /idx/_count",
      "POST /_msearch\n{}\n{}",
      "POST /idx/_explain/1\n{}",
      "POST /idx/_validate/query?explain",
      "POST /_query\n{\"query\":\"FROM logs\"}",
      "POST /_ingest/pipeline/my-pipeline/_simulate\n{}",
      "POST /idx/_refresh",
      "POST /_flush",
      "POST /idx/_cache/clear"
    ]
    for input in allowed {
      XCTAssertNil(DevConsoleReadOnlyPolicy.blockedReason(for: try parse(input)), "Expected '\(input)' to be allowed")
    }
  }

  func testReadOnlyBlocksWrites() throws {
    let blocked = [
      "POST /_bulk\n{\"delete\":{\"_index\":\"idx\",\"_id\":\"1\"}}",
      "POST /idx/_delete_by_query\n{\"query\":{\"match_all\":{}}}",
      // Typed as GET, but sent as POST because of the body
      "GET /idx/_delete_by_query\n{\"query\":{\"match_all\":{}}}",
      "POST /idx/_update_by_query",
      "POST /idx/_doc\n{\"a\":1}",
      // A document id that looks like an endpoint
      "POST /idx/_doc/_search\n{\"a\":1}",
      "POST /idx/_update/1\n{}",
      "POST /_reindex\n{}",
      "POST /idx/_close",
      "POST /idx/_forcemerge",
      "POST /_aliases\n{}",
      "POST /_tasks/_cancel",
      "POST /idx/_rollover",
      "POST /_plugins/_sql\n{\"query\":\"DELETE FROM idx\"}",
      // Paths that could read differently on the server
      "POST /idx/_search/../_delete_by_query",
      "POST /idx/%5Fdelete_by_query",
      "POST /idx/%255Fsearch",
      "POST /",
      "POST /idx"
    ]
    for input in blocked {
      XCTAssertNotNil(DevConsoleReadOnlyPolicy.blockedReason(for: try parse(input)), "Expected '\(input)' to be blocked")
    }
  }

  @MainActor
  func testSendInReadOnlyBlocksWritesWithoutARequest() async throws {
    let session = CapturingURLSession(body: "{}", status: 200)
    Request.mockedSession = session
    defer { Request.mockedSession = nil }

    let result = await DevConsoleService.send(host: makeHost(), request: try parse("POST /_bulk\n{}"), readOnly: true)

    XCTAssertNil(session.lastRequest, "Nothing is sent")
    XCTAssertEqual(result.status, 0)
    XCTAssertEqual(result.sentMethod, .POST)
    XCTAssertEqual(result.path, "/_bulk")
    XCTAssertTrue(result.errorMessage?.hasPrefix("Read only mode is on") ?? false)
  }

  @MainActor
  func testSendWithReadOnlyOffSendsWrites() async throws {
    let session = CapturingURLSession(body: "{\"errors\":false}", status: 200)
    Request.mockedSession = session
    defer { Request.mockedSession = nil }

    let result = await DevConsoleService.send(host: makeHost(), request: try parse("POST /_bulk\n{}"), readOnly: false)

    XCTAssertEqual(session.lastRequest?.httpMethod, "POST")
    XCTAssertEqual(session.lastRequest?.url?.path, "/_bulk")
    XCTAssertNil(result.errorMessage)
  }

  @MainActor
  func testSendInReadOnlyAllowsSearches() async throws {
    let session = CapturingURLSession(body: "{\"took\":1}", status: 200)
    Request.mockedSession = session
    defer { Request.mockedSession = nil }

    let result = await DevConsoleService.send(host: makeHost(), request: try parse("POST /idx/_search\n{}"), readOnly: true)

    XCTAssertEqual(session.lastRequest?.url?.path, "/idx/_search")
    XCTAssertNil(result.errorMessage)
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

  // MARK: curl export

  @MainActor
  func testCurlCommandKeepsMethodPathAndBody() throws {
    let request = try parse("GET /logs-*/_search\n{\n  \"query\": { \"match\": { \"msg\": \"it's\" } }\n}")
    let command = DevConsoleCurlExporter.command(for: request, host: makeHost())

    XCTAssertEqual(command, """
    curl -X GET 'http://localhost:9200/logs-*/_search' \\
      -H 'Content-Type: application/json' \\
      --data-binary '{
      "query": { "match": { "msg": "it'\\''s" } }
    }'
    """)
  }

  @MainActor
  func testCurlCommandLeavesSecretsOut() throws {
    let request = try parse("GET /_cluster/health")

    let basic = makeHost()
    basic.authenticationType = .UsernamePassword
    basic.username = "elastic"
    basic.password = "s3cret"
    let basicCommand = DevConsoleCurlExporter.command(for: request, host: basic)
    XCTAssertTrue(basicCommand.contains("-u 'elastic'"))
    XCTAssertFalse(basicCommand.contains("s3cret"))

    let apiKey = makeHost()
    apiKey.authenticationType = .APIKey
    apiKey.apiKey = "abc123"
    let apiKeyCommand = DevConsoleCurlExporter.command(for: request, host: apiKey)
    XCTAssertTrue(apiKeyCommand.contains("-H \"Authorization: ApiKey ${ES_API_KEY}\""))
    XCTAssertTrue(apiKeyCommand.contains("-H 'kbn-xsrf: true'"))
    XCTAssertFalse(apiKeyCommand.contains("abc123"))

    let aws = makeHost()
    aws.authenticationType = .AWSSigV4
    aws.awsRegion = "eu-west-2"
    aws.awsAccessKeyId = "AKIDEXAMPLE"
    aws.awsSecretAccessKey = "wJalrXUtnFEMI"
    aws.awsSessionToken = "session"
    let awsCommand = DevConsoleCurlExporter.command(for: request, host: aws)
    XCTAssertTrue(awsCommand.contains("--aws-sigv4 'aws:amz:eu-west-2:es'"))
    XCTAssertTrue(awsCommand.contains("${AWS_SESSION_TOKEN}"))
    XCTAssertFalse(awsCommand.contains("AKIDEXAMPLE"))
    XCTAssertFalse(awsCommand.contains("wJalrXUtnFEMI"))
  }

  @MainActor
  func testCurlCommandAddsCustomHeadersAndInsecureFlag() throws {
    let host = makeHost()
    host.host?.selfSignedCertificate = true
    let header = Headers()
    header.header = "X-Tenant"
    header.value = "team-a"
    host.customHeaders.append(header)

    let command = DevConsoleCurlExporter.command(for: try parse("GET /"), host: host)
    XCTAssertTrue(command.contains("--insecure"))
    XCTAssertTrue(command.contains("-H 'X-Tenant: team-a'"))
  }
}
