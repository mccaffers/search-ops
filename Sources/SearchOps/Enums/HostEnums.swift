// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
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
