// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public enum ServiceType: String, PersistableEnum {
    case ElasticSearch
    case OpenSearch
    case notCreated
}

public enum ConnectionType: String, PersistableEnum {
    case CloudID = "Cloud ID"
    case URL = "Host URL"
}

public enum HostScheme: String, PersistableEnum {
    case HTTPS
    case HTTP
}

public enum AuthenticationTypes: String, PersistableEnum {
  case None = "None"
  case UsernamePassword = "Username & Password"
  case AuthToken = "Auth Token"
  case APIToken = "API Token"
  case APIKey = "API Key"
  case AWSSigV4 = "AWS Signature V4"

  // SigV4 signs the host URL, so it isn't offered for Elastic Cloud IDs
  public static func available(for connectionType: ConnectionType) -> [AuthenticationTypes] {
    return allCases.filter { $0.isAvailable(for: connectionType) }
  }

  public func isAvailable(for connectionType: ConnectionType) -> Bool {
    return self != .AWSSigV4 || connectionType == .URL
  }

  // Short label for the macOS button row
  public var shortName: String {
    switch self {
    case .AWSSigV4:
      return "AWS SigV4"
    default:
      return rawValue
    }
  }
}

public enum AWSService: String, PersistableEnum {
  case es
  case aoss

  public var displayName: String {
    switch self {
    case .es:
      return "OpenSearch Service (es)"
    case .aoss:
      return "OpenSearch Serverless (aoss)"
    }
  }
}
