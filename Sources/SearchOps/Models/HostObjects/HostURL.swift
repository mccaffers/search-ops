// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
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
