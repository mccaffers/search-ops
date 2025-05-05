// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

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
      if cloudid.count > 0 ||  host?.url.count ?? 0 > 0 {
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
