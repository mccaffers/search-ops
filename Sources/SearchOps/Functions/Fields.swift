// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

@available(macOS 10.15, *)
@available(iOS 15.0.0, *)

// Fields contains a number of static methods
// to shape fields into objects for presentation

public class Fields {
  
  public init() {}
  
  public static func MakeSquashedArray(key: String, fields: [FieldsArray], squashedArray: [SquasedFieldsArray], keyArray: [String] = [String]()) -> [SquasedFieldsArray] {
    
    var localArray = squashedArray
    
    // Loop around all of the fields
    for item in fields {
      
      // Maintain a local key array
      // is emptied on a new loop, as it takes the keyArray from the function
      // but builds up if the loop calls itself
      var localKeyArray = keyArray
      
      // Add the current key to the array
      localKeyArray.append(item.name)
      
      // lets check if there are any more values to add
      if item.values?.count == 0 {
        
        // By default, lets just add the current item name (eg. date)
        var local = SquasedFieldsArray(id: item.id, squashedString: item.name)
        
        // If there is a key add that with a dot delimiter
        if !key.isEmpty {
          local = SquasedFieldsArray(id: item.id, squashedString: key + "." + item.name)
        }
        
        // build up the key array
        local.fieldParts.append(contentsOf: localKeyArray)
        
        // build up the squashed array
        localArray.append(local)
        
      } else if let fieldArray = item.values {
        
        var localKey = item.name
        
        if !key.isEmpty {
          localKey = key + "." + item.name
        }
        
        localArray = MakeSquashedArray(key:localKey,
                                       fields:fieldArray,
                                       squashedArray: localArray,
                                       keyArray: localKeyArray)
      }
    }
    
    return localArray.sorted { $0.squashedString < $1.squashedString }
  }
  
  
  
  @available(macOS 13.0, *)
  @available(iOS 16.0.0, *)
  @MainActor
  public static func QueryElastic(filterObject: FilterObject,
                                  item: HostDetails?,
                                  selectedIndex: String,
                                  from: Int = 0) async -> ServerResponse {
    
    let queryBuilder = GenericQueryBuilder()
    var response = ServerResponse()
    
    var range : GenericQueryBuilder.Date? = nil
    
    
    var dateField : String? = nil
    
    if filterObject.dateField != nil {
      dateField = filterObject.dateField?.squashedString ?? ""
      if filterObject.relativeRange != nil {
        if let dateRange = filterObject.relativeRange {
          range = GenericQueryBuilder.Date()
          range?.gte = DateTools.dateString(dateRange.GetFromTime())
          range?.lte = "now"
        }
      } else if filterObject.absoluteRange != nil {
        if let dateRange = filterObject.absoluteRange {
          range = GenericQueryBuilder.Date()
          range?.gte = DateTools.dateString(dateRange.from)
          range?.lte = DateTools.dateString(dateRange.to)
        }
      }
    }
    
    var queryArray : [String] = ["*"]
    if let queryList = filterObject.query?.values.compactMap({$0.string}) {
      queryArray = Array(queryList)
    }
    
    var sortBy : [String:String]? = nil
    if let sortObject = filterObject.sort {
      sortBy = [sortObject.field.squashedString:sortObject.order.rawValue]
    }
    
    
    var compound = "must"
    if let availableCompound = filterObject.query?.compound,
       availableCompound == .should {
      compound = "should"
    }
    
    var searchObject = queryBuilder.Create(queries:queryArray,
                                           compound: compound,
                                           dateField: dateField,
                                           range: range,
                                           sortBy: sortBy)
    var settingsManager = SettingsDatatManager()
    searchObject.size = settingsManager.settings?.maximumDocumentsPerPage ?? 25
    searchObject.from = from
    
    let jsonEncoder = JSONEncoder()
    
    do {
      
      let jsonData = try jsonEncoder.encode(searchObject)
      
      let json = String(data: jsonData, encoding: String.Encoding.utf8)
      
      if let item = item {
        response = await Search.searchIndex(serverDetails: item, index: selectedIndex, json: json ?? "")
        
      } else {
        response.error = ResponseError(title:"Request Error",
                                       message: "Invalid JSON",
                                       type:.critical)
      }
      
      response.jsonReq = json
    } catch let error {
      response.error = ResponseError(title:"Request Error",
                                     message: error.localizedDescription,
                                     type:.critical)
    }
    
    return response
  }
  
  public static func getHits(input:String) -> Int {
    
    if let jsonObj = JsonTools.serialiseJson(input) {
      if let hits = jsonObj["hits"] as? [String: Any] {
        if let total = hits["total"] as? [String: Any] {
          if let value = total["value"] as? Int {
            return value
          }
        } else if let total = hits["total"] as? Int {
          return total
        }
      }
      
    }
    
    return 0
  }
  
  
  public static func getFields(input:String) -> [SquasedFieldsArray] {
    
    var headersDictionary =  [FieldsArray]()
    
    if let jsonObj = JsonTools.serialiseJson(input) {
      if let hits = jsonObj["hits"] as? [String: Any] {
        
        if let hits = hits["hits"] as? [[String: Any]] {
          for jsonDict in hits {
            
            if let _source = jsonDict["_source"] as? [String: Any] {
              
              // Pass all of the objects to a loop function
              headersDictionary = loopFields(_source: _source, headersDictionary: headersDictionary)
              
            }
          }
        }
      }
      
    }
    
    return Fields.MakeSquashedArray(key: "", fields: headersDictionary, squashedArray: [SquasedFieldsArray]() )
  }
  
  // Takes all of the elastic objects
  private static func loopFields(_source: [String: Any], headersDictionary: [FieldsArray]) -> [FieldsArray] {
    
    // Local copy of the dictionary
    var localCopy = headersDictionary
    
    for item in _source {
      
      // See if the object exists
      var local = localCopy.first(where: {$0.name == item.key})
      
      // if it doesn't exist lets make one
      if local == nil {
        local = FieldsArray(name: item.key, values: [FieldsArray]())
      }
      
      // Is the object a dictionary
      if let field = item.value as? [String: Any] {
        // Trigger a rabbit hole, inner loop over the values
        local = innerFields(key:item.key, items: field,  fieldsDictionary: local!)
      }
      
      
      // Remove any references to the existing object
      localCopy.removeAll(where: {$0.name == item.key})
      
      // Append an updated version
      localCopy.append(local!)
      
    }
    
    return localCopy
    
  }
  
  private static func innerFields(key: String, items: [String: Any], fieldsDictionary: FieldsArray) -> FieldsArray {
    
    var localCopy = fieldsDictionary
    
    // Loop the inner values
    
    for item in items {
      
      var fieldObj = localCopy.values?.first(where: {$0.name == item.key})
      
      // if it doesn't exist lets make one
      if fieldObj == nil {
        fieldObj = FieldsArray(name: item.key, values: [FieldsArray]())
      }
      
      // is it just a string, so save the key
      if item.value is String {
        
        localCopy.values?.removeAll(where: {$0.name == item.key})
        localCopy.values?.append(fieldObj!)
        
      } else if item.value is Double {
        
        localCopy.values?.removeAll(where: {$0.name == item.key})
        localCopy.values?.append(fieldObj!)
        
      } else if item.value is Array<String> {
        
        localCopy.values?.removeAll(where: {$0.name == item.key})
        localCopy.values?.append(fieldObj!)
        
      } else if item.value is Array<Double> {
        
        localCopy.values?.removeAll(where: {$0.name == item.key})
        localCopy.values?.append(fieldObj!)
        
      } else if let field = item.value as? [String: Any] {
        // if it's not a string, call the same function to pull out it's values
        // and append them
        localCopy.values?.removeAll(where: {$0.name == item.key})
        localCopy.values?.append(innerFields(key: item.key, items: field, fieldsDictionary: fieldObj!))
      }
    }
    
    return localCopy
  }
  
  
}
