// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

/// A class to manage search history data
@available(macOS 13.0, *)
@available(iOS 15.0, *)
@MainActor
public class SearchHistoryDataManager: ObservableObject {
  
  /// Published property to store search history items
  @Published public var items: [RealmSearchEvent] = []
  
  /// Converts Realm objects to static SearchEvent objects
  /// - Returns: An array of SearchEvent objects
  public func staticList() -> [SearchEvent] {
    return items.map { item in
      let event = SearchEvent()
      
      // Convert filter data
      let filterHistory = FilterObject()
      filterHistory.dateField = item.dateField?.eject()
      
      if let relativeRange = item.relativeRange {
        filterHistory.relativeRange = RelativeRangeFilter(period: relativeRange.period, value: relativeRange.value)
      }
      if let absoluteRange = item.absoluteRange {
        filterHistory.absoluteRange = AbsoluteDateRangeObject(from: absoluteRange.from, to: absoluteRange.to)
      }
      
      filterHistory.query = item.query?.eject()
    
      if let sortObject = item.sortObject,
         let fields = sortObject.field?.eject() {
        filterHistory.sort = SortObject(order: sortObject.order, field: fields)
      }
      
      event.filter = filterHistory
      event.host = item.host
      event.index = item.index
      event.date = item.date
      
      return event
    }
  }
  
  public func migrateAwayFromFilterObjects() {
    if let realm = RealmManager().getRealm() {  
      for item in items {
        if let filter = item.filter {
          try? realm.write {
            // new embedded object
            if let dateField = filter.dateField?.copy() {
              item.dateField = dateField
            }
            if let absoluteRange = filter.absoluteRange?.copy() {
              item.absoluteRange = absoluteRange
            }
            if let relativeRange = filter.relativeRange?.copy() {
              item.relativeRange = relativeRange
            }
            item.filter = nil
          }
        }
      }
    }
  }
  
  /// Checks if two dates are in the same day
  /// - Parameters:
  ///   - date1: The first date
  ///   - date2: The second date
  /// - Returns: True if dates are in the same day, false otherwise
  func areDatesSameDay(date1: Date, date2: Date) -> Bool {
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar.isDate(date1, inSameDayAs: date2)
  }
  
  /// Returns the list of search events ordered by date (most recent first)
  /// - Returns: An array of SearchEvent objects sorted by date
  public func orderedByDate() -> [SearchEvent] {
    return staticList().sorted(by: { $0.date > $1.date })
  }
  
  /// Deletes all search history for a specific host
  /// - Parameter id: UUID of the host to delete
  public func deleteByHost(id: UUID) {
    refresh()
    let filteredToHost = items.filter { $0.host == id }
    
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        for host in filteredToHost {
          realm.delete(host)
        }
      }
    }
  }
  
  /// Groups search events by date
  /// - Returns: A dictionary with dates as keys and arrays of SearchEvent as values
  public func groupByDate() -> Dictionary<Date, [SearchEvent]> {
    var dateDictionary: [Date: [SearchEvent]] = [:]
    
    for item in orderedByDate() {
      let calendar = Calendar.current
      let dateComponents = calendar.dateComponents([.year, .month, .day], from: item.date)
      if let dateOnly = calendar.date(from: dateComponents) {
        dateDictionary[dateOnly, default: []].append(item)
      }
    }
    
    return dateDictionary
  }
  
  /// Initializes the SearchHistoryDataManager and loads data from the server
  public init() {
    self.items = readServer()
  }
  
  /// Refreshes the items array with the latest data from the server
  public func refresh() {
    self.items = readServer()
  }
  
  /// Reads search event data from the Realm database
  /// - Returns: An array of RealmSearchEvent objects
  private func readServer() -> [RealmSearchEvent] {
    if let realm = RealmManager().getRealm() {
      let realmArrayObject = realm.objects(RealmSearchEvent.self)
      return Array(realmArrayObject)
    } else {
      return []
    }
  }
  
  /// Checks if a search event entry already exists
  /// - Parameter newEntry: The new RealmSearchEvent to check
  /// - Returns: The existing RealmSearchEvent if found, nil otherwise
  public func checkIfEntryExists(newEntry: RealmSearchEvent) -> RealmSearchEvent? {
      return items.first { currentItem in
          areEntriesMatching(currentItem: currentItem, newEntry: newEntry)
      }
  }

  public func areEntriesMatching(currentItem: RealmSearchEvent, newEntry: RealmSearchEvent) -> Bool {
    
    // Do the host match
    guard currentItem.host == newEntry.host else { return false }
    // Do the indiex match
    guard currentItem.index == newEntry.index else { return false }
    // Do the object match (both nil or both not nil)
    guard ObjectStaticCheck.doBothObjectsMatch(currentItem.query, newEntry.query) else { return false }
    // Do the query strings match
    guard queryStringMatches(currentEntry: currentItem, newEntry: newEntry) else { return false }
    // Do the date fields match
    guard dateFieldMatches(currentEntry: currentItem, newEntry: newEntry) else { return false }
    // Do relative ranges match
    guard areRelativeRangeTheSame(currentEntry: currentItem, newEntry: newEntry) else { return false }
    guard areAbsoluteRangesTheSame(currentEntry: currentItem, newEntry: newEntry) else { return false }
    
    return true
  }

  public func queryStringMatches(currentEntry:RealmSearchEvent, newEntry: RealmSearchEvent) -> Bool {
    if let query = currentEntry.query {
      if query.isEqual(object: newEntry.query) {
        return true
      } else {
        return false
      }
    } else {
      return true
    }
  }
  
  public func dateFieldMatches(currentEntry:RealmSearchEvent, newEntry: RealmSearchEvent) -> Bool {
    if let dateField = currentEntry.dateField {
      if dateField.squashedString == newEntry.dateField?.squashedString {
        return true
      } else {
        return false
      }
    } else {
      return true
    }
  }
  
  public func areRelativeRangeTheSame(currentEntry:RealmSearchEvent, newEntry: RealmSearchEvent) -> Bool {
    if let currentRelativeRange = currentEntry.relativeRange,
       let newRelativeRange = newEntry.relativeRange {
      if currentRelativeRange.value == newRelativeRange.value,
         currentRelativeRange.period == newRelativeRange.period {
        return true
      } else {
        return false
      }
    }
    return true
  }
  
  public func areAbsoluteRangesTheSame(currentEntry:RealmSearchEvent, newEntry: RealmSearchEvent) -> Bool {
    // if either are nil, return true
    if let currentAbsoluteRange = currentEntry.absoluteRange,
       let newAbsoluteRange = newEntry.absoluteRange {
      if currentAbsoluteRange.fromNow == newAbsoluteRange.fromNow,
         currentAbsoluteRange.toNow == newAbsoluteRange.toNow,
         currentAbsoluteRange.from == newAbsoluteRange.from,
         currentAbsoluteRange.to == newAbsoluteRange.to {
        return true
      } else {
        return false
      }
    } else {
      return true
    }
  }
  
  /// Adds a new search event or updates an existing one
  /// - Parameter item: The RealmSearchEvent to add or update
  public func addNew(item: RealmSearchEvent) {
    if let existingItem = checkIfEntryExists(newEntry: item) {
      // Update the time of the existing entry
      if let realm = RealmManager().getRealm() {
        try? realm.write {
          existingItem.date = Date.now
        }
      }
    } else {
      addNewLogEntry(item: item)
    }
  }
  
  /// Adds a new log entry to the Realm database
  /// - Parameter item: The RealmSearchEvent to add
  private func addNewLogEntry(item: RealmSearchEvent) {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        realm.add(item, update: .modified)
      }
    }
  }
  
  /// Deletes all search history entries
  public func deleteAll() {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        let allUploadingObjects = realm.objects(RealmSearchEvent.self)
        realm.delete(allUploadingObjects)
      }
    }
    refresh()
  }
}
