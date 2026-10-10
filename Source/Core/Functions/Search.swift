// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
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
    getObjects(json: JsonTools.serialiseJson(input), input: input)
  }

  /// Reads the documents, fields and errors out of a search response that's already been parsed.
  /// `input` is the raw response, shown when an error can't be read from the JSON.
  public static func getObjects(json: [String: Any]?, input: String) -> SearchResult {

    var hitCount = 0

    var parsedObject = SearchResult()

    if let jsonObj = json {
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
              holder.append(_source)
            }
          }

          // Flatten the documents and find their fields in one pass. A page with no documents keeps
          // the empty result, as it always has.
          if !objects.isEmpty {
            let page = DocumentFlattener.flattenPage(holder)
            parsedObject = SearchResult(data: holder,
                                        hitCount: hitCount,
                                        fields: page.fields.map { SquashedFieldsArray(squashedString: $0.key, fieldParts: $0.parts) },
                                        rows: page.rows)
          }
        }
      } else if let errorMessage = jsonObj["error"] as? [String: Any] {
        
        if let errorItems = errorMessage["root_cause"] as? [[String: Any]] {
          for error in errorItems {
            if let reasonString = error["reason"] as? String {
              let errorType = error["type"] as? String
              parsedObject = SearchResult(error: reasonString, errorTitle: errorType)
              break
            }
          }
        }
        
        if parsedObject.error == nil {
          if let reasonString = errorMessage["reason"] as? String {
            let errorType = errorMessage["type"] as? String
            parsedObject = SearchResult(error: reasonString, errorTitle: errorType)
          } else if let errorType = errorMessage["type"] as? String {
            parsedObject = SearchResult(error: errorType, errorTitle: errorType)
          } else {
            let removeNewLines = JsonTools.tidyUpString(input)
            let firstHundred = String(removeNewLines.prefix(100))
            parsedObject = SearchResult(error: firstHundred, errorTitle: "Query Error")
          }
        }
        
      } else if let errorString = jsonObj["error"] as? String {
        parsedObject = SearchResult(error: errorString, errorTitle: "Error")
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

