// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13.0, *)
@available(iOS 15.0, *)

public class RealmAbsoluteDateRangeObject : EmbeddedObject {
  
  public static func == (lhs: RealmAbsoluteDateRangeObject, rhs: RealmAbsoluteDateRangeObject) -> Bool {
       return lhs.active == rhs.active &&
              lhs.from == rhs.from &&
              lhs.to == rhs.to &&
              lhs.fromNow == rhs.fromNow &&
              lhs.toNow == rhs.toNow
   }

  
  @Persisted public var active: Bool = false
  @Persisted public var from: Date = Date.now
  @Persisted public var to: Date = Date.now
  @Persisted public var fromNow: Bool = false
  @Persisted public var toNow: Bool = false
  
  
  public func isEqual(object: RealmAbsoluteDateRangeObject?) -> Bool {
    guard self.from == object?.from else { return false }
    guard self.to == object?.to else { return false }
    guard self.fromNow == object?.fromNow else { return false }
    guard self.toNow == object?.toNow else { return false }
    return true
  }
  
}

