//
//  File.swift
//  
//
//  Created by Ryan McCaffery on 06/07/2023.
//

import Foundation
import RealmSwift

@available(iOS 15.0, *)
public class LogDataManager: ObservableObject {
    
    @Published
    public var items: [LogEvent] = []
    
    public init() {
        self.items = ReadServer()
    }
    
    public func refresh() {
        self.items = ReadServer()
    }
    
    private func ReadServer() -> [LogEvent] {
         
        if let realm = RealmManager.getRealm() {
            let specificPerson = realm.objects(LogEvent.self)
            return Array(specificPerson)
        } else {
            return []
        }
    }
    
    public func addNew(item: LogEvent) {
        UpdateServerList(item: item);
			RotateLogs()
    }
    
    private func UpdateServerList(item: LogEvent) {
        if let realm = RealmManager.getRealm() {
            try! realm.write {
                realm.add(item, update: Realm.UpdatePolicy.modified)
            }
        }
    }
    
    
	private func RotateLogs() {
			if let realm = RealmManager.getRealm() {
					try! realm.write {
							
						let specificPerson = realm.objects(LogEvent.self)
						let myArray = Array(specificPerson)
						let limit = (myArray.count - 20)
						if limit > 1 {
							if let oldest = myArray.sorted(by: { $0.date < $1.date }).first {
								realm.delete(oldest)
							}
						}
							
					}
			}
	}
	
	
    public func DeleteAll(){
        if let realm = RealmManager.getRealm() {
            try! realm.write {
                let allUploadingObjects = realm.objects(LogEvent.self)
                realm.delete(allUploadingObjects)
            }
        }
			refresh()
    }
}

@available(iOS 15, *)
public class LogEvent : Object {
	
	@Persisted(primaryKey: true) public var id: UUID = UUID()
	
	// Metadata
	@Persisted public var date : Date = Date.now
	
	// Objects
	@Persisted public var host : LogHostDetails? = nil
	@Persisted public var index : String = ""
	@Persisted public var filter : LogFilter? = nil
	
	// Request
	@Persisted public var jsonReq : String = ""
	@Persisted public var method : String = ""
	
	// Response
	@Persisted public var httpStatus : Int = 0
	@Persisted public var jsonRes : String = ""
	@Persisted public var duration : String = ""
	@Persisted public var error : RealmResponseError? = nil
	@Persisted public var page : Int = 0
	@Persisted public var hitCount : Int = 0
}

@available(iOS 15, *)
public class RealmResponseError : EmbeddedObject {
	@Persisted public var title: String
	@Persisted public var message: String
	@Persisted public var type : ErrorResponseType
}


@available(iOS 15, *)
public class LogFilter : EmbeddedObject {
	@Persisted public var query: QueryObject? = nil
	@Persisted public var dateField: RealmSquasedFieldsArray?
	@Persisted public var relativeRange: RealmRelativeRangeFilter?
	@Persisted public var absoluteRange: RealmAbsoluteDateRangeObject?
}
