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
public class IndexMap {
  
  // Fetches index mappings from an Elasticsearch server and processes them into a structured array.
  // The function is designed to be called on the main thread.
  @MainActor
  public static func indexMappings(serverDetails: HostDetails,
                                   index: String) async -> [SquasedFieldsArray] {
    
    let clock = ContinuousClock()  // Used for measuring the duration of the network request.
    var response = ServerResponse()  // Holds the server's response.
    var result = [SquasedFieldsArray]()  // Array to store the processed index mappings.
    
    // Measure the time taken to fetch and process the index mappings.
    let timeTaken = await clock.measure {
      let endpoint = index.isEmpty ? "/_mapping" : "/\(index)/_mapping"
      response = await Request().invoke(serverDetails: serverDetails, endpoint: endpoint)
      
      // If data is received, it is converted to a string.
      if let data = response.data {
        response.parsed = String(bytes: data, encoding: String.Encoding.utf8) ?? ""
      }
    }
    
    // Process the parsed data into a structured array if available.
    if let mappingParsed = response.parsed {
      result = await IndexMap.indexMappingsResponseToArray(mappingParsed)
    }
    
    // Record the duration of the request in the response.
    response.duration = timeTaken
    
    // Log the event with details of the request and response.
    Logger.event(response: response,
                 index: index,
                 host: serverDetails,
                 hitCount: result.count)
    
    return result  // Return the array of structured index mappings.
  }
  
  public static func indexMappingsResponseToArray(_ input: String) async -> [SquasedFieldsArray] {
    
    do {
      let data = Data(input.utf8)
      // make sure this JSON is in the format we expect
      if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        // try to read out a string array
        
        var fieldsArray = [SquasedFieldsArray]()
        var keyArray = Set<String>()
        
        for jsonObj in jsonArray as [String: Any]  {
          
          if let dictionary = jsonObj.value as? [String: Any]{
            
            if let mappingsObj = dictionary["mappings"] as? [String: Any] {
              
              if let propertiesObj = mappingsObj["properties"] as? [String: Any] {
                
                for item in propertiesObj {
                  
                  var myDictionary = Dictionary<String, Any>()
                  myDictionary[item.key]=item.value
                  
                  let output = indexMappingsResponseToArrayLopp(input:myDictionary,
                                                                keyArray: keyArray,
                                                                indexKey: jsonObj.key)
                  
                  
                  output.forEach { keyArray.insert($0.squashedString) }
                  fieldsArray.append(contentsOf: output)
                }
                
                
              } else if let typeKey = mappingsObj.first?.key,
                        let innerObject = mappingsObj[typeKey] as? [String: Any] {
                
                if let propertiesObj = innerObject["properties"] as? [String: Any] {
                  
                  for item in propertiesObj {
                    
                    var myDictionary = Dictionary<String, Any>()
                    myDictionary[item.key]=item.value
                    
                    let output = indexMappingsResponseToArrayLopp(input:myDictionary,
                                                                  keyArray: keyArray,
                                                                  indexKey: jsonObj.key)
                    
                    
                    output.forEach { keyArray.insert($0.squashedString) }
                    fieldsArray.append(contentsOf: output)
                  }
                  
                }
              }
            }
          }
        }
        return fieldsArray
      }
      
    } catch let error as NSError {
      print("Failed to load: \(error.localizedDescription)")
    }
    
    return [SquasedFieldsArray]()
  }
  
  private static func indexMappingsResponseToArrayLopp(input: [String: Any],
                                                       fieldObject: SquasedFieldsArray? = nil,
                                                       keyArray: Set<String>,
                                                       indexKey: String = "")
  -> [SquasedFieldsArray] {
    
    // Create an array
    var localObjArray = [SquasedFieldsArray]()
    
    for key in input.keys {
      
      let localObj = SquasedFieldsArray(squashedString: key)
      
      if fieldObject != nil {
        localObj.fieldParts = fieldObject!.fieldParts
      }
      localObj.fieldParts.append(key)
      
      if let innerObj = input[key] as? [String: Any] {
        
        if let type = innerObj["type"] as? String {
          
          localObj.squashedString = localObj.fieldParts.joined(separator: ".")
          
          if !keyArray.contains(localObj.squashedString) {
            localObj.type = type
            localObj.index = indexKey
            localObjArray.append(localObj)
          }
          
        } else if let propertiesObj = innerObj["properties"] as? [String: Any] {
          
          localObjArray.append(contentsOf:
                                indexMappingsResponseToArrayLopp(input:propertiesObj,
                                                                 fieldObject: localObj,
                                                                 keyArray: keyArray,
                                                                 indexKey: indexKey))
          
        } else {
          localObjArray.append(contentsOf:
                                indexMappingsResponseToArrayLopp(input:innerObj,
                                                                 fieldObject: localObj,
                                                                 keyArray: keyArray,
                                                                 indexKey: indexKey))
          
        }
        
        
      }
      
    }
    
    
    return localObjArray
  }
}
