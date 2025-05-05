// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 10.13, *)
@available(iOS 15.0, *)
public class QueryObject : EmbeddedObject {
  
  public func eject() -> QueryObject {
    let detachedObject = QueryObject()
    
    // Build up the list object
    detachedObject.values = List<QueryFilterObject>()
    for item in values {
      detachedObject.values.append(QueryFilterObject(string:item.string))
    }
    
    // Creating enum's to avoid any references to the existing object
    if self.compound == .must {
      detachedObject.compound = .must
    } else {
      detachedObject.compound = .should
    }
    
    return detachedObject
  }

  @Persisted public var values: List<QueryFilterObject> = List<QueryFilterObject>()
  @Persisted public var compound: QueryCompoundEnum
  
  public func isEqual(object: QueryObject?) -> Bool {
      guard let myObjects = object else { return false }
      guard self.values.count == myObjects.values.count else { return false }
      
      let selfStrings = self.values.map { $0.string }.sorted()
      let objectStrings = myObjects.values.map { $0.string }.sorted()
      
      return selfStrings == objectStrings && self.compound == myObjects.compound
  }

}

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}


public class QueryFilterObject : EmbeddedObject {
    
    public convenience init(string: String = "*") {
        self.init()
        self.string = string
    }
    
    @Persisted public var string: String = "*"
}

