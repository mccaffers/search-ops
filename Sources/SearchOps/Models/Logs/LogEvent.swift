// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13, *)
@available(iOS 13.0, *)
public class LogEvent : Object {
  
  @Persisted(primaryKey: true) public var id: UUID = UUID()
  
  // Metadata
  @Persisted public var date : Date = Date.now
  
  // Objects
  @Persisted public var host : LogHostDetails? = nil
  @Persisted public var index : String = ""
  @Persisted public var filter : LogFilter? = nil
  
  // Request
  @Persisted public var jsonReq : String = ""
  @Persisted public var method : String = ""
  
  // Response
  @Persisted public var httpStatus : Int = 0
  @Persisted public var jsonRes : String = ""
  @Persisted public var duration : String = ""
  @Persisted public var error : RealmResponseError? = nil
  @Persisted public var page : Int = 0
  @Persisted public var hitCount : Int = 0
}
