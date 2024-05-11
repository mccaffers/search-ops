// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public class RequestLogs : Object  {
    @Persisted public var id: UUID = UUID()
    @Persisted public var date: String = ""
    @Persisted public var url: String = ""
    @Persisted public var port: String = ""
    @Persisted public var headers: List<Headers>
}
