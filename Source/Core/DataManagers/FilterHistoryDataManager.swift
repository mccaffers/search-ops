// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import RealmSwift
import Foundation

//
// FilterHistoryDataManager
// Saves Search Filters to Realm
//
@available(macOS 13.0, *)
@available(iOS 15, *)
@MainActor
public class FilterHistoryDataManager: ObservableObject {
  
  @Published public var items: [RealmFilterObject] = []
  
  public init() {
    self.items = readServer()
  }
  
  public func refresh() {
    self.items = readServer()
  }
  
  public func clear() {
    deleteAll()
    self.items = [RealmFilterObject]()
  }
  
  public func addNew(item: RealmFilterObject) {
    updateServerList(item: item);
    refresh()
  }
  

  
  public func checkIfValueExistsForAbsolute(incomingSet: Set<UUID>, absoluteRange: AbsoluteDateRangeObject? = nil) -> Set<UUID> {
    var idSet = incomingSet
    
    if let absoluteRange = absoluteRange {
      let from = items.first(where: {$0.absoluteRange?.from == absoluteRange.from})
      let to = items.first(where: {$0.absoluteRange?.to == absoluteRange.to})
      
      if let from = from,
         let to = to,
         from.id == to.id {
        idSet.insert(from.id)
      }
    }
    return idSet
  }
  
  public func checkIfValueExistsForRelative(incomingSet: Set<UUID>, relativeRange: RelativeRangeFilter? = nil) -> Set<UUID> {
    var idSet = incomingSet
    
    if let relativeRange = relativeRange {
      let range = items.first(where: {$0.relativeRange?.value == relativeRange.value})
      let period = items.first(where: {$0.relativeRange?.period == relativeRange.period})
      
      if let range = range,
         let period = period,
         range.id == period.id {
        idSet.insert(range.id)
      }
      
    }
    return idSet
  }
  
  public func checkIfValueExistsForQuery(incomingSet: Set<UUID>, query: List<QueryFilterObject>? = nil) -> Set<UUID> {
    var idSet = incomingSet
    if let query = query {
      // list exists, convert it to an array
      let queryListArray = Array(query)
      for queryItem in queryListArray {
        
        for item in items {
          if let exists = item.query?.values.contains(where: {$0.string == queryItem.string}),
             exists {
            idSet.insert(item.id)
          }
        }
      }
      
    }
    return idSet
  }
  
  public func checkIfValueExists(query: List<QueryFilterObject>? = nil,
                                 relativeRange: RelativeRangeFilter? = nil,
                                 absoluteRange: AbsoluteDateRangeObject? = nil) -> UUID? {
    
    var countToMatch = 0
    
    if query != nil {
      countToMatch += 1
    }
    
    if relativeRange != nil {
      countToMatch += 1
    }
    
    if absoluteRange != nil {
      countToMatch += 1
    }
    
    // id of objects found
    var idSet = Set<UUID>()
    idSet = checkIfValueExistsForAbsolute(incomingSet: idSet, absoluteRange: absoluteRange)
    idSet = checkIfValueExistsForQuery(incomingSet: idSet, query: query)
    idSet = checkIfValueExistsForRelative(incomingSet: idSet, relativeRange: relativeRange)
    
    if idSet.count == 0 {
      return nil
    } else if idSet.count == countToMatch {
      return idSet.first
    } else  {
      return nil
    }
  }
  
  public func checkIfValueExistsJustQuery(query: List<QueryFilterObject>? = nil) -> UUID? {
    
    
    var countToMatch = 0
    
    if query != nil {
      countToMatch += 1
    }
    
    // id of objects found
    var idSet = Set<UUID>()
    
    idSet = checkIfValueExistsForQuery(incomingSet: idSet, query: query)
    
    if idSet.count == 0 {
      return nil
    } else if idSet.count == countToMatch {
      return idSet.first
    } else  {
      return nil
    }
  }
  
  public func queryObjectExists(_ queryToFind: QueryObject) -> Bool {
    for item in items {
      if let itemQuery = item.query,
         itemQuery.isEqual(object: queryToFind) {
        return true
      }
    }
    
    return false
  }


  public func removeQueryDuplicates() {
    var uniqueItems: [RealmFilterObject] = []
    var seenQueries: Set<String> = []
    
    for item in items {
      if let query = item.query {
        
        // Create a unique string representation of the query
        let queryRepresentation = query.values.map { $0.string }.sorted().joined(separator: ",") + "\(query.compound)"
        
        if !seenQueries.contains(queryRepresentation) {
          uniqueItems.append(item)
          seenQueries.insert(queryRepresentation)
        } else {
          deleteItem(item: item)
        }
      }
    }

  }

  public func updateDateForFilterHistory(id: UUID)  {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        refresh()
        let item = items.first(where: {$0.id == id})
        item?.date = Date.now
        item?.count = (item?.count ?? 0) + 1
      }
    }
  }
  
  private func deleteAll(){
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        let allUploadingObjects = realm.objects(RealmFilterObject.self)
        realm.delete(allUploadingObjects)
      }
    }
  }
  
  private func readServer() -> [RealmFilterObject] {
    if let realm = RealmManager().getRealm() {
      let realmArrayObject = realm.objects(RealmFilterObject.self)
      let res = Array(realmArrayObject)
      return res
    } else {
      return []
    }
  }
  
  func updateServerList(item: RealmFilterObject) {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        realm.add(item, update: .modified)
      }
      refresh()
      
      if items.count > 50 {
        deleteOldest()
      }
    }
  }
  
  func deleteOldest() {
    refresh()
    if let realm = RealmManager().getRealm(),
       let oldest = items.sorted(by: {$0.date < $1.date}).first {
      try? realm.write {
        realm.delete(oldest)
      }
    }
  }
  
  func deleteItem(item: RealmFilterObject) {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        realm.delete(item)
      }
    }
  }
}

