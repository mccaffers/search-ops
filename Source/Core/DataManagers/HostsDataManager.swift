// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import CoreData
import RealmSwift
import Foundation

// HostsDataManager
// Stores host information and utilises Realm DB behind the scenes

@available(macOS 13.0, *)
@available(iOS 15.0, *)
@MainActor
public class HostsDataManager: ObservableObject {
  
  @Published
  public var items: [HostDetails] = []
  {
    didSet {
      status = UUID()
    }
  }
  
  @Published
  public var status : UUID = UUID()
  
  public init() {
    self.items = readServer()
  }
  
  public func refresh() {
    self.items = readServer()
  }
  
  public func getHostByID(_ id: UUID?) -> HostDetails? {
    if let id = id {
      let item = items.first(where: {$0.id == id})
      return item
    } else {
      return nil
    }
  }
  
  public func updateList(item: HostDetails, customHeaders: [LocalHeaders]) {
    
    // Trick to delete by ID
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        item.customHeaders.removeAll()
        
        for header in customHeaders {
          let realmHeader = Headers()
          realmHeader.id = header.id
          realmHeader.header = header.header
          realmHeader.value = header.value
          realmHeader.focusedIndexValue = header.focusedIndexValue
          realmHeader.focusedIndexHeader = header.focusedIndexHeader
          item.customHeaders.append(realmHeader)
        }
        
        
      }
    }
  }
  
  public func addNew(item: HostDetails) {
    
    // if it doesn't exist
    if !items.contains(where: {$0.id == item.id}){
      items.append(item)
      updateServerList(items: items);
      SystemLogger().message("Added a new host \(item.name.truncated(to: 20))")
    } else {
      // if it's being edited, remove the existing
      items.removeAll(where: {$0.id == item.id})
      // add the new
      items.append(item)
      updateServerList(items: items);
      SystemLogger().message("Updated host \(item.name.truncated(to: 20))")
    }
  }
  
  public static func setConncetionType(item: HostDetails, connection: ConnectionType) {
    
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        item.connectionType = connection
        
        if connection == ConnectionType.CloudID {
          item.host?.url = ""
          item.host?.port = ""
        } else if connection == ConnectionType.URL {
          item.cloudid = ""
        }
        
      }
    }
    
  }
  
  public static func setVersion(item: HostDetails, version: String) {
    
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        item.version = version
        
      }
    }
    
  }
  
  public static func removeCustomHeaders(item: HostDetails, id: UUID) {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        if let index = item.customHeaders.index(matching: {$0.id == id}) {
          item.customHeaders.remove(at: index)
          
          var index: Double = 0.0
          for header in item.customHeaders {
            header.focusedIndexHeader = index
            header.focusedIndexValue = index + 0.5
            index+=1
          }
        }
        
      }
    }
  }
  
  public static func setScheme(item: HostDetails, scheme: HostScheme) {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        item.host?.scheme = scheme
      }
    }
  }
  
  public static func detachFromSync(item:HostDetails) {
    
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        
        // we create a shallow copy of the realm obj
        // so that it isn't updated as the user makes changes
        // as they might leave the app or view without wanting to save
        // so we update the id when they hit save
        item.id = item.detachedID
      }
    }
    
  }
  
  public static func saveItem(item:HostDetails) {
    
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        item.draft = false
      }
    }
  }
  
  public static func removeTrailingSlash(item:HostDetails) {
  
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        if let gate = item.host?.url.hasSuffix("/"),
           gate == true,
           let urlWithDroppedBackslash = item.host?.url.dropLast().string {
          item.host?.url = urlWithDroppedBackslash
        }
      }
    }
  }
  
  public static func updateAuthentication(item: HostDetails, selection: AuthenticationTypes ) {
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        item.authenticationType = selection
      }
    }
  }
  
  public static func markForDeletion(item: HostDetails){
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        item.softDelete = true
      }
      
    }
  }
  
  @MainActor
  public func deleteItems(itemsForDeletion: [HostDetails]) async {
    
    // Notes
    // "Delete Request for " + itemsForDeletion.count.string + " items"
    
    if itemsForDeletion.count == 0 {
      return
    }
    
    var localArray : [HostDetails] = [HostDetails]()
    for item in itemsForDeletion {
      
      // Need to populate an array with the correct identifer
      // just incase any of them are edits
      let itemFromWhereSearch = items.first(where: {$0.id == item.id})
      if let itemFromWhereSearch = itemFromWhereSearch {
        localArray.append(itemFromWhereSearch)
      }
      
      items.removeAll(where: {$0.id == item.id})
      
    }
    
    // localarray has been nil checked above with the 'if let itemFromWhereSearch'
    for item in localArray {
      deleteItem(item: item);
    }
    
    refresh()
  }
  
  private func updateServerList(items: [HostDetails]) {
    
    if let realm = RealmManager().getRealm() {
      for item in items {
        try? realm.write {
          realm.add(item, update: Realm.UpdatePolicy.modified)
        }
      }
    }
    
  }
  
  private func readServer() -> [HostDetails] {
    
    if let realm = RealmManager().getRealm() {
      let realmArrayObject = realm.objects(HostDetails.self)
      return Array(realmArrayObject)
    } else {
      return []
    }
  }
  
  public func deleteById(id: UUID) {
    // Get item by ID
    refresh()
    var item = items.first { $0.id == id }
    if item != nil {
      SystemLogger().message("Deleting host \(item?.name.truncated(to: 20))")
      if let realm = RealmManager().getRealm() {
        try? realm.write {
          realm.delete(item!)
          refresh()
        }
      }
    }
  }
  
  public func deleteItem(item: HostDetails) {
    
    SystemLogger().message("Deleting host \(item.name.truncated(to: 20))")
    if let realm = RealmManager().getRealm() {
      try? realm.write {
        realm.delete(item)
        refresh()
      }
    }
  }
  
  public func deleteAll() {
    for var item in items {
      SystemLogger().message("Deleting host \(item.name.truncated(to: 20))")
      if let realm = RealmManager().getRealm() {
        try? realm.write {
          realm.delete(item)
          refresh()
        }
      }
    }
  }
}
