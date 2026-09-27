// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public class HostURL : Object  {
  @Persisted public var scheme: HostScheme = HostScheme.HTTPS // defaults to HTTPS
  @Persisted public var url: String = ""
  @Persisted public var path: String = ""
  @Persisted public var port: String = ""
  @Persisted public var selfSignedCertificate: Bool = false
}

// Splits an address as users paste it, eg. "https://search-x.es.amazonaws.com:443/_dashboards",
// into the parts the host form keeps separately
public struct HostAddress: Equatable {
  public let host: String
  public let scheme: HostScheme?
  public let port: String?

  public init(host: String, scheme: HostScheme? = nil, port: String? = nil) {
    self.host = host
    self.scheme = scheme
    self.port = port
  }

  public static func parse(_ input: String) -> HostAddress {
    var rest = input.trimmingCharacters(in: .whitespacesAndNewlines)
    var scheme: HostScheme? = nil

    let lowercased = rest.lowercased()
    if lowercased.hasPrefix("https://") {
      scheme = .HTTPS
      rest = String(rest.dropFirst("https://".count))
    } else if lowercased.hasPrefix("http://") {
      scheme = .HTTP
      rest = String(rest.dropFirst("http://".count))
    }

    // The URL is built as host:port/endpoint, so a path here can't be used
    if let end = rest.firstIndex(where: { "/?#".contains($0) }) {
      rest = String(rest[..<end])
    }

    // A trailing :port, but not the colons inside a bare IPv6 address
    var port: String? = nil
    if let colon = rest.lastIndex(of: ":") {
      let hostPart = rest[..<colon]
      let portPart = rest[rest.index(after: colon)...]
      let bareIPv6 = hostPart.contains(":") && !hostPart.hasSuffix("]")
      if !bareIPv6 && portPart.allSatisfy({ $0.isASCII && $0.isNumber }) {
        port = portPart.isEmpty ? nil : String(portPart)
        rest = String(hostPart)
      }
    }

    return HostAddress(host: rest, scheme: scheme, port: port)
  }
}
