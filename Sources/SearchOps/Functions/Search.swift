// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

// Functions to build the request

@available(macOS 13.0, *)
@available(iOS 16.0.0, *)
public class Search {
  
  public init() {
    // For a type that’s defined as public, the default initializer is considered internal.
    // If you want a public type to be initializable with a no-argument initializer when used in another module,
    // you must explicitly provide a public no-argument initializer yourself as part of the type’s definition.
    // https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/
    // SonarCloud - swift:S1186
  }
  
  @MainActor
  public static func testHost(serverDetails: HostDetails) async -> ServerResponse {
    
    let clock = ContinuousClock()
    var response = ServerResponse()
    
    let timeTaken = await clock.measure {
      response = await Request().invoke(serverDetails: serverDetails, endpoint: "")
      
      if let data = response.data {
        response.parsed = String(bytes: data, encoding: String.Encoding.utf8) ?? "";
      }
      
    }
    
    response.duration = timeTaken
    Logger.event(response: response,
                 host: serverDetails)
    
    return response
    
  }
  
  
  public static func searchIndex(serverDetails: HostDetails,
                                 index: String,
                                 json: String) async -> ServerResponse {
    
    let clock = ContinuousClock()
    var request = ServerResponse()
    
    let timeTaken = await clock.measure {
      
      var endpoint = "/" + index + "/_search"
      if index.isEmpty {
        endpoint = "/_search"
      }
      
      request = await Request().invoke(serverDetails: serverDetails, endpoint: endpoint, json:json)
      
      if let data = request.data  {
        request.parsed = String(bytes: data, encoding: String.Encoding.utf8) ?? "";
      }
      
    }
    
    request.duration = timeTaken
    
    return request
    
  }
  
  public static func getObjects(input:String) -> SearchResult {
    
    var hitCount = 0
    
    var parsedObject = SearchResult()
    
    var headersDictionary =  [FieldsArray]()
    
    if let jsonObj = JsonTools.serialiseJson(input) {
      if let hits = jsonObj["hits"] as? [String: Any] {
        
        if let total = hits["total"] as? [String: Any] {
          if let value = total["value"] as? Int {
            hitCount = value
          }
        } else if let total = hits["total"] as? Int {
          hitCount = total
        }
        
        if let objects = hits["hits"] as? [[String: Any]] {
          
          var holder : [[String : Any]] = [[String : Any]]()
          
          for jsonDict in objects {
            
            if let _source = jsonDict["_source"] as? [String: Any] {
              // Pass all of the objects to a loop function
              holder.append(_source)
              
              // Pass all of the objects to a loop function
              headersDictionary = Fields.loopFields(_source: _source, headersDictionary: headersDictionary)
              
              
            }
            parsedObject = SearchResult(data:holder, hitCount: hitCount, fields: Fields.makeSquashedArray(key: "", fields: headersDictionary, squashedArray: [SquashedFieldsArray]()))
          }
        }
      } else if let errorMessage = jsonObj["error"] as? [String: Any] {
        
        if let errorItems = errorMessage["root_cause"] as? [[String: Any]] {
          
          for error in errorItems {
            if let reasonString = error["reason"] as? String {
              parsedObject = SearchResult(error:reasonString)
            }
          }
        }
        
      } else {
        
        // Something has gone wrong, lets return the response to the user
        
        // Returning the raw string, removing some new lines
        // incase it's a huge error message
        // and limited to 100 characters to protect the app
        let removeNewLines = JsonTools.tidyUpString(input)
        let firstHundred =  String(removeNewLines.prefix(100))
        parsedObject = SearchResult(error:firstHundred)
        
      }
      
    }
    return parsedObject
  }
}

