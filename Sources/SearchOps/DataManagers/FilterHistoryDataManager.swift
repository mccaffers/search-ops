// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
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
public class FilterHistoryDataManager: ObservableObject {

    @Published public var items: [RealmFilterObject] = []
    
    public init() {
        self.items = ReadServer()
    }
    
    public func refresh() {
        self.items = ReadServer()
    }
    
    public func clear() {
        DeleteAll()
        self.items = [RealmFilterObject]()
    }
    
    public func addNew(item: RealmFilterObject) {
        UpdateServerList(item: item);
        refresh()
    }
    
    public func checkIfValueExists(query: List<QueryFilterObject>? = nil,
                                   relativeRange: RelativeRangeFilter? = nil,
                                   absoluteRange: AbsoluteDateRangeObject? = nil) -> UUID? {

			// id of objects found
        var idSet = Set<UUID>()
        
        if let absoluteRange = absoluteRange {
            let from = items.first(where: {$0.absoluteRange?.from == absoluteRange.from})
            let to = items.first(where: {$0.absoluteRange?.to == absoluteRange.to})
            
            if let from = from,
               let to = to,
               from.id == to.id {
                idSet.insert(from.id)
            }
        }
        
        if let query = query {
					// list exists, convert it to an array
					let queryListArray = Array(query)
					for queryItem in queryListArray {
						
						for item in items {
							if let exists = item.query?.values.contains(where: {$0.string == queryItem.string}),
								 exists == true {
								idSet.insert(item.id)
							}
						}
//						let firstQuery = items.first(where: {$0.query?.values.contains(where: )})
//							if let firstQuery = firstQuery {
//									idSet.insert(firstQuery.id)
//							}
//
					}
				
        }
        
        if let relativeRange = relativeRange {
            let range = items.first(where: {$0.relativeRange?.value == relativeRange.value})
            let period = items.first(where: {$0.relativeRange?.period == relativeRange.period})
            
            if let range = range,
               let period = period,
               range.id == period.id {
                idSet.insert(range.id)
            }
            
        }
        
        if idSet.count == 0 {
            return nil
        } else if idSet.count == 1 {
            return idSet.first
        } else  {
            return nil
        }
        
        
    }
    
    public func updateDateForFilterHistory(id: UUID)  {
        if let realm = RealmManager.getRealm() {
            try! realm.write {
                var item = items.first(where: {$0.id == id})
                item?.date = Date.now
                item?.count = (item?.count ?? 0) + 1
            }
        }
    }

    private func DeleteAll(){
        if let realm = RealmManager.getRealm() {
            try! realm.write {
                let allUploadingObjects = realm.objects(RealmFilterObject.self)
                realm.delete(allUploadingObjects)
            }
        }
    }

    private func ReadServer() -> [RealmFilterObject] {
        if let realm = RealmManager.getRealm() {
            let realmArrayObject = realm.objects(RealmFilterObject.self)
            return Array(realmArrayObject)
        } else {
            return []
        }
    }
    
    private func UpdateServerList(item: RealmFilterObject) {
        if let realm = RealmManager.getRealm() {
            try! realm.write {
                realm.add(item, update: Realm.UpdatePolicy.modified)
            }
            
            if items.count > 50 {
                DeleteOldest()
            }
        }
    }
    
    private func DeleteOldest() {
        if let realm = RealmManager.getRealm() {
            if let oldest = items.sorted(by: {$0.date < $1.date}).first {
                try! realm.write {
                    realm.delete(oldest)
                }
            }
        }
    }
    
    func DeleteItem(item: RealmFilterObject) {
        if let realm = RealmManager.getRealm() {
            try! realm.write {
                realm.delete(item)
            }
        }
    }
}

