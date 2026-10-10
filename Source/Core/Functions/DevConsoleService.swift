// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public enum DevConsoleMethod: String, CaseIterable, Sendable {
  case GET
  case POST
}

/// A request typed into the Dev console, in the Kibana style:
/// the first line is `METHOD /path`, everything after it is the body
public struct DevConsoleRequest: Equatable, Sendable {
  public var method: DevConsoleMethod
  public var path: String
  public var body: String?

  public init(method: DevConsoleMethod, path: String, body: String? = nil) {
    self.method = method
    self.path = path
    self.body = body
  }

  /// URLSession refuses to send a GET with a body, Elasticsearch & OpenSearch
  /// accept POST for every GET endpoint that takes one (_search, _count, ...)
  public var sentMethod: DevConsoleMethod {
    method == .GET && body != nil ? .POST : method
  }
}

public enum DevConsoleParseError: Error, Equatable, LocalizedError {
  case empty
  case missingPath
  case unsupportedMethod(String)
  case invalidPath(String)
  case invalidJSON(String)

  public var errorDescription: String? {
    switch self {
    case .empty:
      return "Enter a request, for example: GET /_cluster/health"
    case .missingPath:
      return "Missing path, the first line should look like: GET /_cluster/health"
    case .unsupportedMethod(let method):
      return "Unsupported method \"\(method)\", only GET and POST are supported"
    case .invalidPath(let line):
      return "Could not read the request line \"\(line)\", expected: METHOD /path"
    case .invalidJSON(let message):
      return "Invalid JSON body: \(message)"
    }
  }
}

public struct DevConsoleParser {

  public static func parse(_ input: String) -> Result<DevConsoleRequest, DevConsoleParseError> {
    let lines = input.components(separatedBy: .newlines)

    // The first non-empty line is the request line
    guard let requestLineIndex = lines.firstIndex(where: {
      !$0.trimmingCharacters(in: .whitespaces).isEmpty
    }) else {
      return .failure(.empty)
    }

    let requestLine = lines[requestLineIndex].trimmingCharacters(in: .whitespaces)
    let parts = requestLine.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)

    guard let methodToken = parts.first,
          let method = DevConsoleMethod(rawValue: methodToken.uppercased()) else {
      return .failure(.unsupportedMethod(parts.first ?? requestLine))
    }

    guard parts.count > 1 else {
      return .failure(.missingPath)
    }

    guard parts.count == 2 else {
      return .failure(.invalidPath(requestLine))
    }

    // Kibana allows the leading slash to be omitted, eg. GET _cat/indices
    var path = parts[1]
    if !path.hasPrefix("/") {
      path = "/" + path
    }

    // The body starts on the first non-empty line after the request line
    guard let bodyStartIndex = lines[(requestLineIndex + 1)...].firstIndex(where: {
      !$0.trimmingCharacters(in: .whitespaces).isEmpty
    }) else {
      return .success(DevConsoleRequest(method: method, path: path))
    }

    // Only trailing whitespace is trimmed, so JSON error columns match the editor
    var bodyText = lines[bodyStartIndex...].joined(separator: "\n")
    while let last = bodyText.last, last.isWhitespace {
      bodyText.removeLast()
    }

    switch validateBody(bodyText, firstLineIndex: bodyStartIndex) {
    case .success(let body):
      return .success(DevConsoleRequest(method: method, path: path, body: body))
    case .failure(let error):
      return .failure(error)
    }
  }

  /// Accepts a single JSON document, or newline delimited JSON (_bulk, _msearch).
  /// `firstLineIndex` is the zero-based editor line the body starts on
  static func validateBody(_ body: String, firstLineIndex: Int = 0) -> Result<String, DevConsoleParseError> {
    let singleDocumentError: String
    do {
      _ = try JSONSerialization.jsonObject(with: Data(body.utf8), options: [.fragmentsAllowed])
      return .success(body)
    } catch {
      singleDocumentError = shiftLineNumbers(in: jsonErrorMessage(error), by: firstLineIndex)
    }

    let ndjsonLines = body.components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }

    if ndjsonLines.count > 1 && ndjsonLines.allSatisfy({ line in
      (try? JSONSerialization.jsonObject(with: Data(line.utf8), options: [])) != nil
    }) {
      // NDJSON must end with a newline
      return .success(ndjsonLines.joined(separator: "\n") + "\n")
    }

    return .failure(.invalidJSON(singleDocumentError))
  }

  /// JSON errors count lines from the start of the body, shift them to editor lines
  static func shiftLineNumbers(in message: String, by offset: Int) -> String {
    guard offset != 0, let regex = try? NSRegularExpression(pattern: "line (\\d+)") else {
      return message
    }
    let shifted = NSMutableString(string: message)
    let matches = regex.matches(in: message, range: NSRange(location: 0, length: shifted.length))
    for match in matches.reversed() {
      let numberRange = match.range(at: 1)
      guard let line = Int(shifted.substring(with: numberRange)) else { continue }
      shifted.replaceCharacters(in: numberRange, with: String(line + offset))
    }
    return shifted as String
  }

  private static func jsonErrorMessage(_ error: Error) -> String {
    let nsError = error as NSError
    if let debug = nsError.userInfo["NSDebugDescription"] as? String, !debug.isEmpty {
      return debug
    }
    return nsError.localizedDescription
  }
}

public struct DevConsoleResult: Sendable {
  public var status: Int
  public var sentMethod: DevConsoleMethod
  public var path: String
  public var duration: Duration?
  public var body: String
  public var isJSON: Bool
  public var errorMessage: String?
  public var isCancelled: Bool

  public init(status: Int,
              sentMethod: DevConsoleMethod,
              path: String,
              duration: Duration? = nil,
              body: String = "",
              isJSON: Bool = false,
              errorMessage: String? = nil,
              isCancelled: Bool = false) {
    self.status = status
    self.sentMethod = sentMethod
    self.path = path
    self.duration = duration
    self.body = body
    self.isJSON = isJSON
    self.errorMessage = errorMessage
    self.isCancelled = isCancelled
  }

  /// Shown when the user cancels a request before the cluster responds
  public static func cancelled(_ request: DevConsoleRequest) -> DevConsoleResult {
    DevConsoleResult(status: 0,
                     sentMethod: request.sentMethod,
                     path: request.path,
                     errorMessage: "Request cancelled",
                     isCancelled: true)
  }
}

@MainActor
public struct DevConsoleService {

  public static func send(host: HostDetails, request: DevConsoleRequest) async -> DevConsoleResult {
    let clock = ContinuousClock()
    let start = clock.now

    let response = await Request().invoke(serverDetails: host,
                                          endpoint: request.path,
                                          json: request.body,
                                          method: request.sentMethod.rawValue)

    let duration = clock.now - start

    // A cancelled request never got an answer, so there's nothing to record
    if !Task.isCancelled {
      response.duration = duration
      response.jsonReq = request.body
      if let data = response.data {
        response.parsed = String(decoding: data, as: UTF8.self)
      }
      Logger.event(response: response, host: host, source: LogEvent.devConsoleSource)
    }

    if let error = response.error {
      return DevConsoleResult(status: response.httpStatus,
                              sentMethod: request.sentMethod,
                              path: request.path,
                              duration: duration,
                              errorMessage: error.message)
    }

    let formatted = formatBody(response.data ?? Data())
    return DevConsoleResult(status: response.httpStatus,
                            sentMethod: request.sentMethod,
                            path: request.path,
                            duration: duration,
                            body: formatted.text,
                            isJSON: formatted.isJSON)
  }

  /// Pretty prints JSON bodies, anything else (eg. _cat output) is returned as-is
  nonisolated static func formatBody(_ data: Data) -> (text: String, isJSON: Bool) {
    let raw = String(decoding: data, as: UTF8.self)
    guard !data.isEmpty,
          (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) != nil else {
      return (raw, false)
    }
    return (reindentJSON(raw), true)
  }

  /// Re-indents valid JSON without re-serialising it, so key order and
  /// number formatting are exactly as the cluster returned them
  nonisolated static func reindentJSON(_ json: String, indent: String = "  ") -> String {
    var output = ""
    var depth = 0
    var inString = false
    var escaped = false
    let characters = Array(json)
    var index = 0

    func newline() {
      output.append("\n")
      output.append(String(repeating: indent, count: depth))
    }

    while index < characters.count {
      let char = characters[index]

      if inString {
        output.append(char)
        if escaped {
          escaped = false
        } else if char == "\\" {
          escaped = true
        } else if char == "\"" {
          inString = false
        }
        index += 1
        continue
      }

      switch char {
      case "\"":
        inString = true
        output.append(char)
      case "{", "[":
        // Keep empty containers on one line, eg. {} or []
        let closing: Character = char == "{" ? "}" : "]"
        var next = index + 1
        while next < characters.count && characters[next].isWhitespace {
          next += 1
        }
        if next < characters.count && characters[next] == closing {
          output.append(char)
          output.append(closing)
          index = next
        } else {
          output.append(char)
          depth += 1
          newline()
        }
      case "}", "]":
        depth = max(0, depth - 1)
        newline()
        output.append(char)
      case ",":
        output.append(char)
        newline()
      case ":":
        output.append(": ")
      case _ where char.isWhitespace:
        break
      default:
        output.append(char)
      }
      index += 1
    }

    return output
  }
}

/// Turns a Dev console request into a curl command for a terminal.
/// Secrets never go into the command: passwords are prompted for by curl,
/// tokens and keys are read from shell variables
public struct DevConsoleCurlExporter {

  @MainActor
  public static func command(for request: DevConsoleRequest, host: HostDetails) -> String {
    var lines = ["curl -X \(request.method.rawValue) \(shellQuote(Request.buildUrl(host, request.path)))"]

    if host.host?.selfSignedCertificate == true {
      lines.append("--insecure")
    }

    lines.append("-H \(shellQuote("Content-Type: application/json"))")
    lines.append(contentsOf: authorisation(for: host))

    for header in host.customHeaders where !header.header.isEmpty {
      if host.authenticationType == .AWSSigV4, Request.isReservedForSigV4(header: header.header) {
        continue
      }
      lines.append("-H \(shellQuote("\(header.header): \(header.value)"))")
    }

    if let body = request.body {
      // --data-binary keeps the newlines _bulk and _msearch need
      lines.append("--data-binary \(shellQuote(body))")
    }

    return lines.joined(separator: " \\\n  ")
  }

  /// Mirrors Request.authorisation, with every secret swapped for a placeholder
  @MainActor
  static func authorisation(for host: HostDetails) -> [String] {
    func basic(username: String) -> [String] { ["-u \(shellQuote(username))"] }
    let bearer = ["-H \"Authorization: Bearer ${ES_API_TOKEN}\""]
    let apiKey = ["-H \"Authorization: ApiKey ${ES_API_KEY}\"", "-H \(shellQuote("kbn-xsrf: true"))"]
    let authToken = ["-H \"Authorization: Basic ${ES_AUTH_TOKEN}\""]

    switch host.authenticationType {
    case .AWSSigV4:
      var region = host.awsRegion.trimmingCharacters(in: .whitespacesAndNewlines)
      if region.isEmpty, let detected = AWSEndpoint.detect(host.host?.url ?? "") {
        region = detected.region
      }
      var lines = ["--aws-sigv4 \(shellQuote("aws:amz:\(region):\(host.awsService.rawValue)"))",
                   "--user \"${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}\""]
      if !host.awsSessionToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        lines.append("-H \"x-amz-security-token: ${AWS_SESSION_TOKEN}\"")
      }
      return lines
    case .AuthToken:
      return host.authToken.isEmpty ? [] : authToken
    case .UsernamePassword:
      return host.username.isEmpty ? [] : basic(username: host.username)
    case .APIToken:
      return host.apiToken.isEmpty ? [] : bearer
    case .APIKey:
      return host.apiKey.isEmpty ? [] : apiKey
    case .None:
      if !host.authToken.isEmpty { return authToken }
      if !host.username.isEmpty { return basic(username: host.username) }
      if !host.apiToken.isEmpty { return bearer }
      if !host.apiKey.isEmpty { return apiKey }
      return []
    }
  }

  /// Single quotes stop the shell expanding anything, a ' inside becomes '\''
  static func shellQuote(_ value: String) -> String {
    "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
  }
}
