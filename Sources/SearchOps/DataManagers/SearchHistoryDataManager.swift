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
@MainActor
public class SearchHistoryDataManager: ObservableObject {
  
  @Published
  public var items: [RealmSearchEvent] = []
  
  public func staticList() -> [SearchEvent] {
    
    var filterArray = [SearchEvent]()
    for item in items {
      
      let event = SearchEvent()
      
      let filterHistory = item.filter?.eject()
      filterHistory?.dateField = item.filter?.dateField?.eject()
      
      if let relativeRange = item.filter?.relativeRange {
        filterHistory?.relativeRange = RelativeRangeFilter(period: relativeRange.period, value: relativeRange.value)
      }
      if let absoluteRange = item.filter?.absoluteRange {
        filterHistory?.absoluteRange = AbsoluteDateRangeObject(from: absoluteRange.from, to: absoluteRange.to)
      }
      
      filterHistory?.query = item.filter?.query?.eject()
      
      if let filterHistory = filterHistory {
        event.filter = filterHistory
        
      }
      
      event.host = item.host
      event.index = item.index
      event.date = item.date
      
      filterArray.append(event)

    }
    
    return filterArray
  }
  
  func areDatesSameDay(date1: Date, date2: Date) -> Bool {
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar.isDate(date1, inSameDayAs: date2)
  }
  
  public func orderedByDate() -> [SearchEvent] {
    return staticList().sorted(by: {$0.date > $1.date})
  }
  
  private func isSameDate(previous: SearchEvent, for event: SearchEvent, at index: Int) -> Bool {
    if index == 0 {
      return true
    }
    
    if areDatesSameDay(date1: previous.date, date2: event.date) {
      return false
    } else {
      return true
    }
  }
  
  public func groupByDate() -> Dictionary<Date, [SearchEvent]> {

    var dateDictionary: [Date: [SearchEvent]] = [:]

    for item in orderedByDate() {
      let calendar = Calendar.current
      let dateComponents = calendar.dateComponents([.year, .month, .day], from: item.date)
      if let dateOnly = calendar.date(from: dateComponents){
        
        if var valuesArray = dateDictionary[dateOnly] {
            // If the date key exists, append the new value to the array
            valuesArray.append(item)
            dateDictionary[dateOnly] = valuesArray
        } else {
            // If the date key does not exist, create a new array with the value
            dateDictionary[dateOnly] = [item]
        }
      }
    }
    
    return dateDictionary
  
  }
  
  public init() {
    self.items = readServer()
  }
  
  public func refresh() {
    self.items = readServer()
  }
  
  
  private func readServer() -> [RealmSearchEvent] {
    
    if let realm = RealmManager().getRealm() {
      let realmArrayObject = realm.objects(RealmSearchEvent.self)
      return Array(realmArrayObject)
    } else {
      return []
    }
  }
  
  
  public func checkIfEntryExists(newEntry:RealmSearchEvent) -> RealmSearchEvent? {
    
    for item in items {
      if item.host == newEntry.host,
         item.index == item.index,
         item.filter?.equals(input: newEntry.filter) ?? false
      {
        return item
      }
         
    }
    return nil
    
  }
  
  public func addNew(item: RealmSearchEvent) {
    var response = checkIfEntryExists(newEntry: item)
    if response != nil {
      // it exists just update the time
      if let realm = RealmManager().getRealm() {
        try? realm.write {
          response?.date = Date.now
        }
        
        
      }
//      addNewLogEntry(item: response!);
    } else {
      addNewLogEntry(item: item);
    }
    
//    rotateLogs()
  }
  
  private func addNewLogEntry(item: RealmSearchEvent) {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        realm.add(item, update: Realm.UpdatePolicy.modified)
      }
    }
  }
  
  
  private func rotateLogs() {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        
        let realmArrayObject = realm.objects(RealmSearchEvent.self)
        let myArray = Array(realmArrayObject)
        let limit = (myArray.count - 20)
        if limit > 1 {
          if let oldest = myArray.sorted(by: { $0.date < $1.date }).first {
            realm.delete(oldest)
          }
        }
        
      }
    }
  }
  
  
  public func deleteAll(){
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        let allUploadingObjects = realm.objects(RealmSearchEvent.self)
        realm.delete(allUploadingObjects)
      }
    }
    refresh()
  }
}

