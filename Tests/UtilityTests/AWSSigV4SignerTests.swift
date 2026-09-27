// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import CryptoKit

@testable import Search_Ops

// Captures the last request so tests can check what would be sent
final class CapturingURLSession: URLSessionProtocol {
  var lastRequest: URLRequest?
  let body: String
  let status: Int

  init(body: String = "{}", status: Int = 200) {
    self.body = body
    self.status = status
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    lastRequest = request
    let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
    return (Data(body.utf8), response)
  }
}

@available(iOS 16.0.0, *)
final class AWSSigV4SignerTests: XCTestCase {

  // 2026-09-26T12:34:56Z
  let fixedDate = Date(timeIntervalSince1970: 1790426096)
  let accessKey = "AKIDEXAMPLE"
  let secretKey = "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"
  let sessionToken = "FQoGZXIvYXdzEXAMPLE/token+with=chars"

  override func tearDown() {
    Request.mockedSession = nil
    super.tearDown()
  }

  private func signer(region: String = "eu-west-2", service: String = "es", token: Bool = true) -> AWSSigV4Signer {
    let credentials = AWSCredentials(accessKeyId: accessKey,
                                     secretAccessKey: secretKey,
                                     sessionToken: token ? sessionToken : nil)
    let date = fixedDate
    return AWSSigV4Signer(credentials: credentials, region: region, service: service, now: { date })
  }

  private func request(_ url: String, method: String = "GET", body: String? = nil) -> URLRequest {
    var request = URLRequest(url: URL(string: url)!)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = body.map { Data($0.utf8) }
    return request
  }

  // MARK: - AWS SigV4 test suite vectors

  private func vectorSignature(_ canonical: String) -> (stringToSign: String, signature: String) {
    let stringToSign = AWSSigV4Signer.stringToSign(canonicalRequest: canonical,
                                                   amzDate: "20150830T123600Z",
                                                   scope: "20150830/us-east-1/service/aws4_request")
    let key = AWSSigV4Signer.signingKey(secretAccessKey: secretKey,
                                        dateStamp: "20150830",
                                        region: "us-east-1",
                                        service: "service")
    let mac = HMAC<SHA256>.authenticationCode(for: Data(stringToSign.utf8), using: key)
    return (stringToSign, mac.map { String(format: "%02x", $0) }.joined())
  }

  func testVectorGetVanilla() {
    var request = URLRequest(url: URL(string: "https://example.amazonaws.com/")!)
    request.httpMethod = "GET"

    let canonical = AWSSigV4Signer.canonicalRequest(
      for: request,
      signedHeaders: ["host": "example.amazonaws.com", "x-amz-date": "20150830T123600Z"],
      payloadHash: AWSSigV4Signer.hexSHA256(Data()))

    XCTAssertEqual(canonical, """
      GET
      /

      host:example.amazonaws.com
      x-amz-date:20150830T123600Z

      host;x-amz-date
      e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
      """)

    let result = vectorSignature(canonical)
    XCTAssertEqual(result.stringToSign, """
      AWS4-HMAC-SHA256
      20150830T123600Z
      20150830/us-east-1/service/aws4_request
      bb579772317eb040ac9ed261061d46c1f17a8133879d6129b6e1c25292927e63
      """)
    XCTAssertEqual(result.signature, "5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31")
  }

  func testVectorGetVanillaQueryOrderKeyCase() {
    var request = URLRequest(url: URL(string: "https://example.amazonaws.com/?Param2=value2&Param1=value1")!)
    request.httpMethod = "GET"

    let canonical = AWSSigV4Signer.canonicalRequest(
      for: request,
      signedHeaders: ["host": "example.amazonaws.com", "x-amz-date": "20150830T123600Z"],
      payloadHash: AWSSigV4Signer.hexSHA256(Data()))

    XCTAssertEqual(canonical.split(separator: "\n", omittingEmptySubsequences: false)[2], "Param1=value1&Param2=value2")
    XCTAssertEqual(vectorSignature(canonical).signature,
                   "b97d918cfa904a5beff61c982a1b6f458b799221646efd99d3219ec94cdf2500")
  }

  // MARK: - Canonical URI and query, for the paths the app sends

  private func canonicalURI(_ url: String) -> String {
    return AWSSigV4Signer.canonicalURI(URL(string: url))
  }

  func testCanonicalURIEncodesTheWirePathOnceMore() {
    XCTAssertEqual(canonicalURI("https://h/sigv4-a,sigv4-b/_search"), "/sigv4-a%2Csigv4-b/_search")
    XCTAssertEqual(canonicalURI("https://h/_stats/docs,store"), "/_stats/docs%2Cstore")
    XCTAssertEqual(canonicalURI("https://h/sigv4-*/_search"), "/sigv4-%2A/_search")
    XCTAssertEqual(canonicalURI("https://h/.sigv4-hidden/_search"), "/.sigv4-hidden/_search")
    XCTAssertEqual(canonicalURI("https://h/idx/_doc/a%20b"), "/idx/_doc/a%2520b")
    XCTAssertEqual(canonicalURI("https://h/_tasks/n1:1"), "/_tasks/n1%3A1")
  }

  func testCanonicalURIForEmptyPathIsSlash() {
    XCTAssertEqual(canonicalURI("https://h"), "/")
    XCTAssertEqual(canonicalURI("https://h:443"), "/")
    XCTAssertEqual(canonicalURI("https://h/"), "/")
  }

  private func canonicalQuery(_ url: String) -> String {
    return AWSSigV4Signer.canonicalQuery(URL(string: url))
  }

  func testCanonicalQuery() {
    XCTAssertEqual(canonicalQuery("https://h/"), "")
    XCTAssertEqual(canonicalQuery("https://h/?pretty=true"), "pretty=true")
    XCTAssertEqual(canonicalQuery("https://h/_cat/indices?v&format=json"), "format=json&v=")
    XCTAssertEqual(
      canonicalQuery("https://h/i/_delete_by_query?wait_for_completion=false&refresh=true&conflicts=proceed&expand_wildcards=none"),
      "conflicts=proceed&expand_wildcards=none&refresh=true&wait_for_completion=false")
    XCTAssertEqual(canonicalQuery("https://h/?a=2&a=1&b=x%2Cy"), "a=1&a=2&b=x%2Cy")
  }

  func testHostHeaderLeavesOutTheDefaultPort() {
    XCTAssertEqual(AWSSigV4Signer.hostHeader(for: URL(string: "https://Search-X.eu-west-2.es.amazonaws.com:443/")!),
                   "search-x.eu-west-2.es.amazonaws.com")
    XCTAssertEqual(AWSSigV4Signer.hostHeader(for: URL(string: "https://h")!), "h")
    XCTAssertEqual(AWSSigV4Signer.hostHeader(for: URL(string: "http://h:80")!), "h")
    XCTAssertEqual(AWSSigV4Signer.hostHeader(for: URL(string: "https://h:9200")!), "h:9200")
    XCTAssertEqual(AWSSigV4Signer.hostHeader(for: URL(string: "http://h:443")!), "h:443")
  }

  func testAmzDateIsUTCAndGregorian() {
    XCTAssertEqual(AWSSigV4Signer.amzDate(fixedDate), "20260926T123456Z")
  }

  // MARK: - Full signatures, checked against botocore's SigV4Auth

  func testSignPostWithSessionTokenMatchesBotocore() {
    let signed = signer().sign(request(
      "https://search-demo-abc123.eu-west-2.es.amazonaws.com:443/sigv4-a,sigv4-b/_search?pretty=true",
      method: "POST",
      body: "{\"query\":{\"match_all\":{}}}"))

    XCTAssertEqual(signed.value(forHTTPHeaderField: "Authorization"),
                   "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20260926/eu-west-2/es/aws4_request, "
                   + "SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date;x-amz-security-token, "
                   + "Signature=041345f59f7338ce14df6b5fb5f6edfe61f32a96256ba4c2e497eb055d1b751d")
    XCTAssertEqual(signed.value(forHTTPHeaderField: "X-Amz-Date"), "20260926T123456Z")
    XCTAssertEqual(signed.value(forHTTPHeaderField: "X-Amz-Security-Token"), sessionToken)
    XCTAssertEqual(signed.value(forHTTPHeaderField: "X-Amz-Content-Sha256"),
                   AWSSigV4Signer.hexSHA256(Data("{\"query\":{\"match_all\":{}}}".utf8)))
    XCTAssertNil(signed.value(forHTTPHeaderField: "Host"))
  }

  func testSignRootWithoutSessionTokenMatchesBotocore() {
    let signed = signer(token: false).sign(request("https://search-demo-abc123.eu-west-2.es.amazonaws.com"))

    XCTAssertEqual(signed.value(forHTTPHeaderField: "Authorization"),
                   "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20260926/eu-west-2/es/aws4_request, "
                   + "SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date, "
                   + "Signature=bc837cda01e74db35fba647c6df1e0703eb7e5618aae865f595252eeec327f4a")
    XCTAssertNil(signed.value(forHTTPHeaderField: "X-Amz-Security-Token"))
  }

  func testSignServerlessWithPortAndValuelessQueryMatchesBotocore() {
    let signed = signer(region: "us-east-1", service: "aoss")
      .sign(request("https://abc123.us-east-1.aoss.amazonaws.com:9200/_cat/indices?v&format=json"))

    XCTAssertEqual(signed.value(forHTTPHeaderField: "Authorization"),
                   "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20260926/us-east-1/aoss/aws4_request, "
                   + "SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date;x-amz-security-token, "
                   + "Signature=08494a1b696531cbeac92485a504df0f94f86803ae01ab493f744d4cfc569139")
  }

  func testSignReplacesExistingAuthHeaders() {
    var original = request("https://h/")
    original.addValue("stale", forHTTPHeaderField: "Authorization")
    original.addValue("stale", forHTTPHeaderField: "X-Amz-Date")

    let signed = signer().sign(original)

    XCTAssertEqual(signed.value(forHTTPHeaderField: "X-Amz-Date"), "20260926T123456Z")
    XCTAssertTrue(signed.value(forHTTPHeaderField: "Authorization")?.hasPrefix("AWS4-HMAC-SHA256 ") ?? false)
    XCTAssertFalse(signed.value(forHTTPHeaderField: "Authorization")?.contains("stale") ?? true)
  }

  // MARK: - Endpoint detection

  func testDetectRegionAndService() {
    XCTAssertEqual(AWSEndpoint.detect("search-logs-abc123.eu-west-2.es.amazonaws.com")?.region, "eu-west-2")
    XCTAssertEqual(AWSEndpoint.detect("search-logs-abc123.eu-west-2.es.amazonaws.com")?.service, .es)
    XCTAssertEqual(AWSEndpoint.detect("vpc-logs-abc123.us-east-1.es.amazonaws.com")?.region, "us-east-1")
    XCTAssertEqual(AWSEndpoint.detect("abc123.us-west-2.aoss.amazonaws.com")?.service, .aoss)
    XCTAssertEqual(AWSEndpoint.detect("search-x-1.cn-north-1.es.amazonaws.com.cn")?.region, "cn-north-1")
    XCTAssertEqual(AWSEndpoint.detect("https://Search-X-1.EU-WEST-1.es.amazonaws.com:443/path")?.region, "eu-west-1")
  }

  func testDetectRejectsOtherHosts() {
    XCTAssertNil(AWSEndpoint.detect(""))
    XCTAssertNil(AWSEndpoint.detect("localhost"))
    XCTAssertNil(AWSEndpoint.detect("search.example.com"))
    XCTAssertNil(AWSEndpoint.detect("sns.us-east-1.amazonaws.com"))
    XCTAssertNil(AWSEndpoint.detect("es.amazonaws.com"))
  }

  // MARK: - Responses

  func testErrorMessages() {
    XCTAssertEqual(AWSSigV4Response.errorMessage(for: "{\"message\":\"Signature expired: 20260926T120000Z is now earlier than 20260926T122934Z (20260926T123434Z - 5 min.)\"}"),
                   "Your device clock is more than 5 minutes out. Check the date and time settings.")
    XCTAssertEqual(AWSSigV4Response.errorMessage(for: "Signature not yet current: x is still later than y"),
                   "Your device clock is more than 5 minutes out. Check the date and time settings.")
    XCTAssertEqual(AWSSigV4Response.errorMessage(for: "{\"message\":\"Credential should be scoped to a valid region.\"}"),
                   "The region doesn't match this endpoint.")
    XCTAssertEqual(AWSSigV4Response.errorMessage(for: "{\"message\":\"The security token included in the request is invalid.\"}"),
                   "The session token is missing, invalid or expired. Paste new temporary credentials.")
    XCTAssertEqual(AWSSigV4Response.errorMessage(for: "{\"__type\":\"ExpiredToken\"}"),
                   "The session token is missing, invalid or expired. Paste new temporary credentials.")
    XCTAssertEqual(AWSSigV4Response.errorMessage(for: "{\"message\":\"The request signature we calculated does not match the signature you provided.\"}"),
                   "Signature mismatch. Check the secret access key.")
    XCTAssertNil(AWSSigV4Response.errorMessage(for: "{\"error\":\"no permissions for [indices:data/read/search]\"}"))
  }

  func testRedactRawAndJSONEscapedToken() {
    let raw = Data("x-amz-security-token:\(sessionToken)\n".utf8)
    XCTAssertEqual(String(data: AWSSigV4Response.redact(raw, sessionToken: sessionToken), encoding: .utf8),
                   "x-amz-security-token:<redacted>\n")

    let escaped = Data("{\"message\":\"token:FQoGZXIvYXdzEXAMPLE\\/token+with=chars\"}".utf8)
    XCTAssertEqual(String(data: AWSSigV4Response.redact(escaped, sessionToken: sessionToken), encoding: .utf8),
                   "{\"message\":\"token:<redacted>\"}")

    XCTAssertEqual(AWSSigV4Response.redact(raw, sessionToken: nil), raw)
  }

  // MARK: - Request.invoke

  private func sigV4Host() -> HostDetails {
    let host = HostDetails()
    host.connectionType = .URL
    host.host?.scheme = .HTTPS
    host.host?.url = "search-demo-abc123.eu-west-2.es.amazonaws.com"
    host.host?.port = "443"
    host.authenticationType = .AWSSigV4
    host.awsAccessKeyId = accessKey
    host.awsSecretAccessKey = secretKey
    host.awsSessionToken = sessionToken
    return host
  }

  @MainActor
  func testInvokeSignsRequestAndDropsCollidingHeaders() async {
    let session = CapturingURLSession()
    Request.mockedSession = session

    let host = sigV4Host()
    for (name, value) in [("Content-Type", "text/plain"), ("Authorization", "Basic x"),
                          ("X-Amz-Date", "bad"), ("X-Custom", "kept")] {
      let header = Headers()
      header.header = name
      header.value = value
      host.customHeaders.append(header)
    }

    _ = await Request().invoke(serverDetails: host, endpoint: "/sigv4-a,sigv4-b/_search", json: "{}")

    let sent = session.lastRequest
    XCTAssertEqual(sent?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    XCTAssertEqual(sent?.value(forHTTPHeaderField: "X-Custom"), "kept")
    XCTAssertEqual(sent?.value(forHTTPHeaderField: "X-Amz-Security-Token"), sessionToken)
    XCTAssertNotEqual(sent?.value(forHTTPHeaderField: "X-Amz-Date"), "bad")

    // The region comes from the hostname when the field is empty
    let authorization = sent?.value(forHTTPHeaderField: "Authorization") ?? ""
    XCTAssertTrue(authorization.hasPrefix("AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/"), authorization)
    XCTAssertTrue(authorization.contains("/eu-west-2/es/aws4_request"), authorization)
    XCTAssertFalse(authorization.contains("Basic"))
  }

  @MainActor
  func testInvokeRedactsTokenAndMapsSignatureMismatch() async {
    let body = "{\"message\":\"The request signature we calculated does not match the signature you provided. "
      + "The Canonical String for this request should have been 'x-amz-security-token:\(sessionToken)'\"}"
    Request.mockedSession = CapturingURLSession(body: body, status: 403)

    let response = await Request().invoke(serverDetails: sigV4Host(), endpoint: "/")

    XCTAssertEqual(response.error?.message, "Signature mismatch. Check the secret access key.")
    let returned = String(data: response.data ?? Data(), encoding: .utf8) ?? ""
    XCTAssertFalse(returned.contains(sessionToken))
    XCTAssertFalse(returned.contains("Canonical String"))
  }

  @MainActor
  func testInvokeLeavesOtherResponsesAlone() async {
    Request.mockedSession = CapturingURLSession(body: "{\"error\":\"forbidden\"}", status: 403)

    let response = await Request().invoke(serverDetails: sigV4Host(), endpoint: "/")

    XCTAssertNil(response.error)
    XCTAssertEqual(String(data: response.data ?? Data(), encoding: .utf8), "{\"error\":\"forbidden\"}")
  }

  @MainActor
  func testCustomHeadersAreSentNameFirst() async {
    let session = CapturingURLSession()
    Request.mockedSession = session

    let host = HostDetails()
    host.authenticationType = .APIKey
    host.apiKey = "abc"
    let header = Headers()
    header.header = "X-Custom"
    header.value = "value"
    host.customHeaders.append(header)

    _ = await Request().invoke(serverDetails: host, endpoint: "/")

    XCTAssertEqual(session.lastRequest?.value(forHTTPHeaderField: "kbn-xsrf"), "true")
    XCTAssertEqual(session.lastRequest?.value(forHTTPHeaderField: "X-Custom"), "value")
    XCTAssertEqual(session.lastRequest?.value(forHTTPHeaderField: "Authorization"), "ApiKey abc")
  }

  // MARK: - Model

  func testSigV4IsOnlyOfferedForHostURLs() {
    XCTAssertFalse(AuthenticationTypes.available(for: .CloudID).contains(.AWSSigV4))
    XCTAssertTrue(AuthenticationTypes.available(for: .URL).contains(.AWSSigV4))
    XCTAssertEqual(AuthenticationTypes.available(for: .CloudID).count, AuthenticationTypes.allCases.count - 1)
    XCTAssertTrue(AuthenticationTypes.UsernamePassword.isAvailable(for: .CloudID))
  }

  func testGenerateCopyKeepsAWSFields() {
    let copy = sigV4Host().generateCopy()

    XCTAssertEqual(copy.authenticationType, .AWSSigV4)
    XCTAssertEqual(copy.awsAccessKeyId, accessKey)
    XCTAssertEqual(copy.awsSecretAccessKey, secretKey)
    XCTAssertEqual(copy.awsSessionToken, sessionToken)
    XCTAssertEqual(copy.awsService, .es)
  }

  func testSwitchingAuthTypeClearsTheOtherCredentials() {
    let host = sigV4Host()
    host.awsRegion = "eu-west-2"
    host.awsService = .aoss
    host.authenticationType = .None

    XCTAssertEqual(host.awsAccessKeyId, "")
    XCTAssertEqual(host.awsSecretAccessKey, "")
    XCTAssertEqual(host.awsSessionToken, "")
    XCTAssertEqual(host.awsRegion, "")
    XCTAssertEqual(host.awsService, .es)

    host.authenticationType = .UsernamePassword
    host.username = "user"
    host.authenticationType = .AWSSigV4
    XCTAssertEqual(host.username, "")
  }
}
