// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(iOS 15, *)
public class LogHostDetails : Object  {
    @Persisted public var name: String = ""
    @Persisted public var host: HostURL? = HostURL()
    @Persisted public var env: String = ""
}
