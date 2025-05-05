// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

@available(macOS 13.0, *)
@MainActor 
class SearchMainViewLogic {
  
  static func SaveFilter(filterObject : FilterObject) {
    
    let saveFilteredObj = FilterHistoryDataManager()
    let realmFilter = RealmFilterObject()
    
    if let dateField = filterObject.dateField {
      realmFilter.dateField = RealmSquashedFieldsArray(squasedField: dateField)
    }
    
    if let queryObj = filterObject.query {
      realmFilter.query = queryObj.eject()
    }
    
    if let relativeRange = filterObject.relativeRange {
      realmFilter.relativeRange = relativeRange.ejectRealmObject()
    }
    
    if let absoluteRange = filterObject.absoluteRange {
      realmFilter.absoluteRange = absoluteRange.ejectRealmObject()
    }
    
    // No point adding more if all the values are empty
    if realmFilter.query != nil ||
        realmFilter.relativeRange != nil ||
        realmFilter.absoluteRange != nil {
      
      let idValue = saveFilteredObj.checkIfValueExists(
        query:filterObject.query?.values,
        relativeRange: filterObject.relativeRange,
        absoluteRange:filterObject.absoluteRange)
      
      if let idValue = idValue {
        // update date
        print("updating date")
        saveFilteredObj.updateDateForFilterHistory(id: idValue)
      } else {
        saveFilteredObj.addNew(item: realmFilter)
      }
    }
    
  }
}
