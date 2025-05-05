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
}
