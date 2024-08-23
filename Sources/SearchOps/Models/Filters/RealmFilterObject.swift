// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift


@available(macOS 13, *)
@available(iOS 15.0, *)
public class RealmSearchFilterObject: RealmFilterObject {
}

public class ObjectStaticCheck {
  public static func doBothObjectsMatch <T>(_ obj1: T?, _ obj2: T?) -> Bool {
      if obj1 == nil && obj2 != nil {
          return false
      }
      if obj1 != nil && obj2 == nil {
          return false
      }
      return true
  }
}

@available(macOS 13, *)
@available(iOS 15.0, *)
public class RealmFilterObject: Object {
  
  @Persisted(primaryKey: true) public var id: UUID = UUID()
  @Persisted public var query: QueryObject? = nil
  @Persisted public var dateField: RealmSquashedFieldsArray?
  @Persisted public var relativeRange: RealmRelativeRangeFilter?
  @Persisted public var absoluteRange: RealmAbsoluteDateRangeObject?
  @Persisted public var date: Date = Date.now
  @Persisted public var count: Int = 1
  
  public func eject()  -> FilterObject {
    var filter = FilterObject()
    filter.query = self.query?.eject()
    filter.dateField = self.dateField?.eject()
    if let relativeRange = filter.relativeRange {
      filter.relativeRange = RelativeRangeFilter(period: relativeRange.period, value: relativeRange.value)
    }
    if let absoluteRange = filter.absoluteRange {
      filter.absoluteRange = AbsoluteDateRangeObject(from: absoluteRange.from, to: absoluteRange.to)
    }
    return filter
  }
  
  public func equals (input: RealmFilterObject?) -> Bool {
    
    // Check if query is nil
    guard ObjectStaticCheck.doBothObjectsMatch(self.query, input?.query) else { return false }
    
    if let queryObject = input?.query,
       let selfQuery = self.query {
      if selfQuery.isEqual(object: queryObject) == false {
        return false
      }
    }
            
    guard ObjectStaticCheck.doBothObjectsMatch(self.dateField, input?.dateField) else { return false }
    
    if let dateFieldInput = input?.dateField,
       let dateField = self.dateField {
      if dateField.isEqual(object: dateFieldInput) == false {
        return false
      }
    }
    
    guard ObjectStaticCheck.doBothObjectsMatch(self.relativeRange, input?.relativeRange) else { return false }
    
    if let relativeRange = input?.relativeRange,
        let selfRelativeRange = self.relativeRange {
      if selfRelativeRange.isEqual(object: relativeRange) == false {
        return false
      }
    }
    
    guard ObjectStaticCheck.doBothObjectsMatch(self.absoluteRange, input?.absoluteRange) else { return false }
    
    if let absoluteRange = input?.absoluteRange,
        let selfAbsoluteRange = self.absoluteRange {
      if selfAbsoluteRange.isEqual(object: absoluteRange) == false {
        return false
      }
    }
    
    return true
   }
  

  
}


