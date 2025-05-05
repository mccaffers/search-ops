// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

@MainActor
class SearchMainViewLogic2 {
  
  static func SaveFilter(filterObject : FilterObject, manager:FilterHistoryDataManager) {
    
    print("SearchMainViewLogic.SaveFilter called")
    
    if let queryObj = filterObject.query {
      
      let realmFilter = RealmFilterObject()
      realmFilter.query = queryObj.eject()

      // No point adding more if all the values are empty
      if realmFilter.query != nil {
        
        let found = manager.queryObjectExists(queryObj)
        if !found {
          print("SearchMainViewLogic.SaveFilter addNew")
          manager.addNew(item: realmFilter)
        }
      }
    }
  }
  
  
}
