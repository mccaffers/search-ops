// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public enum ServiceType: String, PersistableEnum {
    case ElasticSearch
    case OpenSearch
    case notCreated
}

public enum ConnectionType: String, PersistableEnum {
    case CloudID = "Cloud ID"
    case URL = "Host URL"
}

public enum HostScheme: String, PersistableEnum {
    case HTTPS
    case HTTP
}

public enum AuthenticationTypes: String, PersistableEnum {
	case None = "None"
	case UsernamePassword = "Username & Password"
	case AuthToken = "Auth Token"
	case APIToken = "API Token"
	case APIKey = "API Key"
}

public class RequestLogs : Object  {
    @Persisted public var id: UUID = UUID()
    @Persisted public var date: String = ""
    @Persisted public var url: String = ""
    @Persisted public var port: String = ""
    @Persisted public var headers: List<Headers>
}

@available(macOS 13.0, *)
@available(iOS 13.0, *)
public class LocalHeaders : ObservableObject, Identifiable, Equatable  {
    
    public static func == (lhs: LocalHeaders, rhs: LocalHeaders) -> Bool {
        return lhs.id == rhs.id
    }
    
    public init(id: UUID = UUID(), header: String = "", value: String = "", focusedIndexHeader: Double = 0, focusedIndexValue: Double = 0) {
        self.id = id
        self.header = header
        self.value = value
        self.focusedIndexHeader = focusedIndexHeader
        self.focusedIndexValue = focusedIndexValue
    }
    

    @Published public var id: UUID = UUID()
    @Published public var header: String = ""
    @Published public var value: String = ""
    @Published public var focusedIndexHeader: Double = 0
    @Published public var focusedIndexValue: Double = 0
}

public class Headers : Object  {
    @Persisted public var id: UUID = UUID()
    @Persisted public var header: String = ""
    @Persisted public var value: String = ""
    @Persisted public var focusedIndexHeader: Double = 0
    @Persisted public var focusedIndexValue: Double = 0
}

public class HostURL : Object  {
	@Persisted public var scheme: HostScheme = HostScheme.HTTPS // defaults to HTTPS
	@Persisted public var url: String = ""
	@Persisted public var path: String = ""
	@Persisted public var port: String = ""
}

@available(iOS 15, *)
public class LogHostDetails : Object  {
    @Persisted public var name: String = ""
//    @Persisted public var cloudid: String = ""
    @Persisted public var host: HostURL? = HostURL()
    @Persisted public var env: String = ""
}

@available(macOS 13.0, *)
@available(iOS 15, *)
public class HostDetails : Object  {
	
	@Persisted(primaryKey: true) public var id: UUID
	@Persisted public var name: String = ""
	@Persisted public var cloudid: String = ""
	@Persisted public var host: HostURL? = HostURL()
	@Persisted public var env: String = ""
	@Persisted public var username: String = ""
	@Persisted public var password: String = ""
	@Persisted public var authToken: String = ""
	@Persisted public var apiToken: String = ""
	@Persisted public var apiKey: String = ""
	@Persisted public var version: String = ""
	@Persisted public var customHeaders: List<Headers>
	@Persisted public var draft: Bool = true
	@Persisted public var createdDate: Date = Date.now
	@Persisted public var updatedDate: Date = Date.now
	@Persisted public var softDelete: Bool = false
	@Persisted public var detachedID: UUID = UUID()
	@Persisted public var connectionType = ConnectionType.CloudID // Defaults
	@Persisted public var authenticationType = AuthenticationTypes.None // Defaults
	{
		didSet {
			if authenticationType == .APIKey {
				self.username = ""
				self.password = ""
				self.authToken = ""
				self.apiToken = ""
			} else if authenticationType == .AuthToken {
				self.username = ""
				self.password = ""
				self.apiKey = ""
				self.apiToken = ""
			} else if authenticationType == .UsernamePassword {
				self.authToken = ""
				self.apiKey = ""
				self.apiToken = ""
			} else if authenticationType == .APIToken {
				self.authToken = ""
				self.apiKey = ""
				self.username = ""
				self.password = ""
			}
		}
	}
	
	public func isValid() -> Bool {
		
		// Name must be filled in
		if name.count > 0 {
			
			// Must have either a cloudID or a host url
			if cloudid.count > 0 {
				return true
			} else if host?.url.count ?? 0 > 0{
				return true
			}
		}
		
		return false
	}
	
	public func updateHeaders(_ headersArray:[LocalHeaders]) {
		customHeaders = List<Headers>()
		
		for item in headersArray {
			let realmHeader = Headers()
			realmHeader.id = item.id
			realmHeader.header = item.header
			realmHeader.focusedIndexValue = item.focusedIndexValue
			realmHeader.focusedIndexHeader = item.focusedIndexHeader
			customHeaders.append(realmHeader)
		}
		
		print("ERRORRRRR")
	}
	
	public func generateCopy() -> HostDetails {
		
		let copy = HostDetails()
		copy.detachedID = self.id
		copy.name = self.name.string
		copy.cloudid = self.cloudid
		copy.host = self.host
		copy.env = self.env
		copy.username = self.username
		copy.password = self.password
		copy.authToken = self.authToken
		copy.apiToken = self.apiToken
		copy.apiKey = self.apiKey
		copy.version = self.version
		copy.customHeaders = self.customHeaders
		copy.createdDate = self.createdDate
		copy.updatedDate = Date.now
		copy.draft = self.draft
		copy.connectionType = self.connectionType
		copy.authenticationType = self.authenticationType
		
		return copy
	}
	
	public func getLocalHeaders() -> [LocalHeaders] {
		var localArray = [LocalHeaders]()
		for item in self.customHeaders {
			let localHeader = LocalHeaders()
			localHeader.id = item.id
			localHeader.header = item.header
			localHeader.value = item.value
			localHeader.focusedIndexValue = item.focusedIndexValue
			localHeader.focusedIndexHeader = item.focusedIndexHeader
			localArray.append(localHeader)
		}
		return localArray
	}
	
}

public enum BuiltInQueries: String, PersistableEnum {
    case Indexes
    case IndexMappings
    case SearchIndex
    case CustomSearch
}

//UNUSUED
public class SavedQueries : Object  {
    @Persisted(primaryKey: true) public var id: UUID = UUID()
    @Persisted public var builtInQuery: BuiltInQueries = BuiltInQueries.Indexes
    @Persisted public var hostID: UUID?
    @Persisted public var detachedID: UUID?
    
    public func generateCopy() -> SavedQueries {
        
        let copy = SavedQueries()
        copy.detachedID = self.id
        copy.builtInQuery = self.builtInQuery
        copy.hostID = self.hostID
        
        return copy
    }
}
