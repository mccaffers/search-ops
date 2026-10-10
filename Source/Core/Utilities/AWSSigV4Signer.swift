// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import CryptoKit

// Signs a request as the last step before it's sent
protocol RequestSigner {
  func sign(_ request: URLRequest) -> URLRequest
}

struct AWSCredentials {
  let accessKeyId: String
  let secretAccessKey: String
  let sessionToken: String?
}

// AWS Signature Version 4, as accepted by Amazon OpenSearch Service (es)
// and OpenSearch Serverless (aoss). See aws-sigv4.md for the verified rules.
struct AWSSigV4Signer: RequestSigner {
  let credentials: AWSCredentials
  let region: String
  let service: String
  var now: () -> Date = Date.init

  static let algorithm = "AWS4-HMAC-SHA256"

  /// Returns a copy of `request` with X-Amz-Date, X-Amz-Content-Sha256,
  /// optional X-Amz-Security-Token and Authorization set (setValue, not addValue).
  func sign(_ request: URLRequest) -> URLRequest {
    guard let url = request.url else {
      return request
    }

    var signed = request

    // Read the clock once, for both the timestamp and the scope
    let amzDate = Self.amzDate(now())
    let dateStamp = String(amzDate.prefix(8))
    let payloadHash = Self.hexSHA256(request.httpBody ?? Data())

    signed.setValue(amzDate, forHTTPHeaderField: "X-Amz-Date")
    signed.setValue(payloadHash, forHTTPHeaderField: "X-Amz-Content-Sha256")

    var headers = [
      "host": Self.hostHeader(for: url),
      "x-amz-date": amzDate,
      "x-amz-content-sha256": payloadHash
    ]

    if let token = credentials.sessionToken, !token.isEmpty {
      signed.setValue(token, forHTTPHeaderField: "X-Amz-Security-Token")
      headers["x-amz-security-token"] = token
    } else {
      signed.setValue(nil, forHTTPHeaderField: "X-Amz-Security-Token")
    }

    if let contentType = signed.value(forHTTPHeaderField: "Content-Type") {
      headers["content-type"] = contentType
    }

    let canonical = Self.canonicalRequest(for: signed, signedHeaders: headers, payloadHash: payloadHash)
    let scope = "\(dateStamp)/\(region)/\(service)/aws4_request"
    let stringToSign = Self.stringToSign(canonicalRequest: canonical, amzDate: amzDate, scope: scope)
    let key = Self.signingKey(secretAccessKey: credentials.secretAccessKey,
                              dateStamp: dateStamp,
                              region: region,
                              service: service)
    let signature = Self.hex(HMAC<SHA256>.authenticationCode(for: Data(stringToSign.utf8), using: key))

    let authorization = "\(Self.algorithm) Credential=\(credentials.accessKeyId)/\(scope), "
      + "SignedHeaders=\(Self.signedHeaderList(headers)), Signature=\(signature)"
    signed.setValue(authorization, forHTTPHeaderField: "Authorization")

    return signed
  }

  // MARK: - Signing steps, exposed for tests against AWS's published vectors

  static func canonicalRequest(for request: URLRequest,
                               signedHeaders: [String: String],
                               payloadHash: String) -> String {
    let url = request.url
    let method = request.httpMethod ?? "GET"

    let canonicalHeaders = signedHeaders
      .map { (name: $0.key.lowercased(), value: canonicalHeaderValue($0.value)) }
      .sorted { $0.name < $1.name }
      .map { "\($0.name):\($0.value)\n" }
      .joined()

    return [
      method,
      canonicalURI(url),
      canonicalQuery(url),
      canonicalHeaders,
      signedHeaderList(signedHeaders),
      payloadHash
    ].joined(separator: "\n")
  }

  static func stringToSign(canonicalRequest: String, amzDate: String, scope: String) -> String {
    return [
      algorithm,
      amzDate,
      scope,
      hexSHA256(Data(canonicalRequest.utf8))
    ].joined(separator: "\n")
  }

  static func signingKey(secretAccessKey: String,
                         dateStamp: String,
                         region: String,
                         service: String) -> SymmetricKey {
    var key = SymmetricKey(data: Data("AWS4\(secretAccessKey)".utf8))
    for part in [dateStamp, region, service, "aws4_request"] {
      key = SymmetricKey(data: Data(HMAC<SHA256>.authenticationCode(for: Data(part.utf8), using: key)))
    }
    return key
  }

  // MARK: - Canonical request parts

  /// The path exactly as it's sent, with each segment URI-encoded once more.
  /// Not `URL.path`, which is decoded.
  static func canonicalURI(_ url: URL?) -> String {
    guard let url = url,
          let path = URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedPath,
          !path.isEmpty else {
      return "/"
    }

    return path
      .split(separator: "/", omittingEmptySubsequences: false)
      .map { uriEncode(String($0)) }
      .joined(separator: "/")
  }

  /// Decoded names and values, re-encoded with the strict set,
  /// sorted by name and then value. A key with no value signs as `key=`.
  static func canonicalQuery(_ url: URL?) -> String {
    guard let url = url,
          let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedQuery,
          !query.isEmpty else {
      return ""
    }

    let pairs: [(name: String, value: String)] = query
      .split(separator: "&")
      .map { item in
        let parts = item.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        let name = String(parts[0])
        let value = parts.count > 1 ? String(parts[1]) : ""
        return (uriEncode(name.removingPercentEncoding ?? name),
                uriEncode(value.removingPercentEncoding ?? value))
      }

    return pairs
      .sorted { $0.name == $1.name ? $0.value < $1.value : $0.name < $1.name }
      .map { "\($0.name)=\($0.value)" }
      .joined(separator: "&")
  }

  /// The URL's host, plus `:port` only when the port isn't the default for the scheme.
  static func hostHeader(for url: URL) -> String {
    let host = (url.host ?? "").lowercased()

    guard let port = url.port else {
      return host
    }

    let scheme = url.scheme?.lowercased()
    if (scheme == "https" && port == 443) || (scheme == "http" && port == 80) {
      return host
    }
    return "\(host):\(port)"
  }

  static func signedHeaderList(_ headers: [String: String]) -> String {
    return headers.keys.map { $0.lowercased() }.sorted().joined(separator: ";")
  }

  // Trim, and collapse runs of spaces to one
  private static func canonicalHeaderValue(_ value: String) -> String {
    return value
      .trimmingCharacters(in: .whitespaces)
      .split(separator: " ", omittingEmptySubsequences: true)
      .joined(separator: " ")
  }

  // MARK: - Encoding and hashing

  private static let unreserved = CharacterSet(
    charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")

  /// URI-encodes everything except `A-Z a-z 0-9 - _ . ~`
  static func uriEncode(_ value: String) -> String {
    return value.addingPercentEncoding(withAllowedCharacters: unreserved) ?? value
  }

  static func amzDate(_ date: Date) -> String {
    return amzDateFormatter.string(from: date)
  }

  private static let amzDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
    return formatter
  }()

  static func hexSHA256(_ data: Data) -> String {
    return hex(SHA256.hash(data: data))
  }

  private static func hex<D: Sequence>(_ bytes: D) -> String where D.Element == UInt8 {
    return bytes.map { String(format: "%02x", $0) }.joined()
  }
}

// Reads the region and service from an Amazon OpenSearch endpoint hostname
enum AWSEndpoint {

  /// `search-<domain>-<id>.<region>.es.amazonaws.com` → (region, .es)
  /// `vpc-<domain>-<id>.<region>.es.amazonaws.com`    → (region, .es)
  /// `<id>.<region>.aoss.amazonaws.com`               → (region, .aoss)
  /// China regions end in `.amazonaws.com.cn`.
  static func detect(_ host: String) -> (region: String, service: AWSService)? {
    var name = host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    // Accept a pasted URL as well as a bare hostname
    if let range = name.range(of: "://") {
      name = String(name[range.upperBound...])
    }
    name = String(name.prefix { $0 != "/" && $0 != ":" && $0 != "?" })

    var labels = name.split(separator: ".").map(String.init)
    if labels.suffix(3) == ["amazonaws", "com", "cn"] {
      labels.removeLast(3)
    } else if labels.suffix(2) == ["amazonaws", "com"] {
      labels.removeLast(2)
    } else {
      return nil
    }

    guard labels.count >= 3,
          let service = AWSService(rawValue: labels[labels.count - 1]) else {
      return nil
    }

    let region = labels[labels.count - 2]
    guard region.contains("-") else {
      return nil
    }

    return (region, service)
  }
}

// Turns SigV4 403 bodies into messages a user can act on,
// and keeps the session token out of anything that's stored or shown
enum AWSSigV4Response {

  /// A user-facing message for a SigV4 auth failure, or nil if the body isn't one
  static func errorMessage(for body: String) -> String? {
    if body.contains("Signature expired") || body.contains("Signature not yet current") {
      return "Your device clock is more than 5 minutes out. Check the date and time settings."
    }
    if body.contains("Credential should be scoped to a valid region") {
      return "The region doesn't match this endpoint."
    }
    if body.contains("The security token included in the request is invalid")
        || body.contains("The security token included in the request is expired")
        || body.contains("ExpiredToken") {
      return "The session token is missing, invalid or expired. Paste new temporary credentials."
    }
    if body.contains("The request signature we calculated does not match") {
      return "Signature mismatch. Check the secret access key."
    }
    return nil
  }

  /// Signature-mismatch 403s echo the canonical string, which contains the
  /// session token. Replace it, raw or JSON-escaped, with `<redacted>`.
  static func redact(_ data: Data, sessionToken: String?) -> Data {
    guard let token = sessionToken, !token.isEmpty,
          let body = String(data: data, encoding: .utf8) else {
      return data
    }

    let escaped = token.replacingOccurrences(of: "/", with: "\\/")
    let redacted = body
      .replacingOccurrences(of: token, with: "<redacted>")
      .replacingOccurrences(of: escaped, with: "<redacted>")

    return redacted == body ? data : Data(redacted.utf8)
  }
}
