// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import CoreData
import RealmSwift
import Foundation

// HostsDataManager
// Stores host information and utilises Realm DB behind the scenes

@available(macOS 13.0, *)
@available(iOS 15.0, *)
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
		self.items = ReadServer()
	}
	
	public func refresh() {
		self.items = ReadServer()
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
		//        let getItem = items.first(where: {$0.id == item.id})
		//        if let getItem = getItem {
		if let realm = RealmManager.getRealm() {
			try! realm.write {
				item.customHeaders.removeAll()
				
				//                var realmHeaderArray = [Headers]()
				
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
			//            }
			//        }
		}
	}
	
	public func addNew(item: HostDetails) {
		
		// if it doesn't exist
		if !items.contains(where: {$0.id == item.id}){
			items.append(item)
			UpdateServerList(items: items);
		} else {
			// if it's being edited, remove the existing
			items.removeAll(where: {$0.id == item.id})
			// add the new
			items.append(item)
			UpdateServerList(items: items);
		}
	}
	
	public static func setConncetionType(item: HostDetails, connection: ConnectionType) {
		
		if let realm = RealmManager.getRealm() {
			try! realm.write {
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
		
		if let realm = RealmManager.getRealm() {
			try! realm.write {
				item.version = version
				
			}
		}
		
	}
	
	public static func RemoveHeaders(headers: [Headers], id: UUID) {
		//        headers.removeAll()
	}
	
	public static func RemoveCustomHeaders(item: HostDetails, id: UUID) {
		if let realm = RealmManager.getRealm() {
			try! realm.write {
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
	
	public static func SetScheme(item: HostDetails, scheme: HostScheme) {
		if let realm = RealmManager.getRealm() {
			try! realm.write {
				item.host?.scheme = scheme
			}
		}
	}
	
	public static func DetachFromSync(item:HostDetails) {
		
		if let realm = RealmManager.getRealm() {
			try! realm.write {
				
				// we create a shallow copy of the realm obj
				// so that it isn't updated as the user makes changes
				// as they might leave the app or view without wanting to save
				// so we update the id when they hit save
				item.id = item.detachedID
			}
		}
		
		
		
	}
	
	public static func SaveItem(item:HostDetails) {
		
		
		if let realm = RealmManager.getRealm() {
			try! realm.write {
				item.draft = false
			}
		}
	}
	
	public static func RemoveTrailingSlash(item:HostDetails) {
		
		
		if let realm = RealmManager.getRealm() {
			try! realm.write {
				if let gate = item.host?.url.hasSuffix("/"),
					 gate == true{
					if let urlWithDroppedBackslash = item.host?.url.dropLast().string {
						item.host?.url = urlWithDroppedBackslash
					}
				}
			}
		}
	}
	
	public static func UpdateAuthentication(item: HostDetails, selection: AuthenticationTypes ) {
		if let realm = RealmManager.getRealm() {
			try! realm.write {
				item.authenticationType = selection
			}
		}
	}
	
	public static func MarkForDeletion(item: HostDetails){
		if let realm = RealmManager.getRealm() {
			try! realm.write {
				item.softDelete = true
			}
			
		}
	}
	
	@MainActor
	public func deleteItems(itemsForDeletion: [HostDetails]) async {
		//        print("Delete Request for " + itemsForDeletion.count.string + " items")
		
		var localArray : [HostDetails] = [HostDetails]()
		for item in itemsForDeletion {
			
			// need to populate an array with the correct id
			// just incase any of them are edits
			let itemFromWhereSearch = items.first(where: {$0.id == item.id})
			if let itemFromWhereSearch = itemFromWhereSearch {
				localArray.append(itemFromWhereSearch)
			}
			
			items.removeAll(where: {$0.id == item.id})
			
		}
		
		// localarray has been nil checked above with the 'if let itemFromWhereSearch'
		for item in localArray {
			DeleteItem(item: item);
		}
	}
	
	private func UpdateServerList(items: [HostDetails]) {
		
		if let realm = RealmManager.getRealm() {
			for item in items {
				try! realm.write {
					realm.add(item, update: Realm.UpdatePolicy.modified)
				}
			}
		}
		
	}
	
	private func ReadServer() -> [HostDetails] {
		
		if let realm = RealmManager.getRealm() {
			let realmArrayObject = realm.objects(HostDetails.self)
			return Array(realmArrayObject)
		} else {
			return []
		}
	}
	
	public func DeleteItem(item: HostDetails) {
		if let realm = RealmManager.getRealm() {
			try! realm.write {
				realm.delete(item)
				refresh()
			}
		}
		
	}
}
