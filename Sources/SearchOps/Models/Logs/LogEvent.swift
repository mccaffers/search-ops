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


@available(macOS 13, *)
@available(iOS 13.0, *)
public class RealmSearchEvent : Object {
  
  @Persisted(primaryKey: true) public var id: UUID = UUID()
  
  // Metadata
  @Persisted public var date : Date = Date.now
  
  // Objects
  @Persisted public var host : UUID? = nil
  @Persisted public var index : String = ""
  
  // Request
  @Persisted public var filter : RealmFilterObject? = nil
  @Persisted public var query: QueryObject? = nil
  @Persisted public var dateField: RealmSquashedFieldsArray?
  @Persisted public var relativeRange: RealmRelativeRangeFilter?
  @Persisted public var absoluteRange: RealmAbsoluteDateRangeObject?

 
}


@available(macOS 13, *)
@available(iOS 13.0, *)
public class SearchEvent : ObservableObject {

  // Metadata
  public var date : Date = Date.now
  
  // Objects
  public var host : UUID? = nil
  public var index : String = ""
  
  // Request
  public var filter : FilterObject? = nil
 
}
