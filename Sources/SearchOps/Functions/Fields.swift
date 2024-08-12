// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

@available(macOS 10.15, *)
@available(iOS 15.0.0, *)

// Fields contains a number of static methods
// to shape fields into objects for presentation

public class Fields {
  
  public init() {
    // For a type that’s defined as public, the default initializer is considered internal.
    // If you want a public type to be initializable with a no-argument initializer when used in another module,
    // you must explicitly provide a public no-argument initializer yourself as part of the type’s definition.
    // https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/
    // SonarCloud - swift:S1186
  }
  
  public static func makeSquashedArray(key: String, fields: [FieldsArray], squashedArray: [SquashedFieldsArray], keyArray: [String] = [String]()) -> [SquashedFieldsArray] {
    
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
        var local = SquashedFieldsArray(id: item.id, squashedString: item.name)
        
        // If there is a key add that with a dot delimiter
        if !key.isEmpty {
          local = SquashedFieldsArray(id: item.id, squashedString: key + "." + item.name)
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
        
        localArray = makeSquashedArray(key:localKey,
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
          if dateRange.fromNow {
            range?.gte = DateTools.dateString(Date.now)
          } else {
            range?.gte = DateTools.dateString(dateRange.from)
          }
          
          if dateRange.toNow {
            range?.lte = DateTools.dateString(Date.now)
          } else {
            range?.lte = DateTools.dateString(dateRange.to)
          }
        }
      }
    }
    
    var queryArray : [String] = ["*"]
    if let queryList = filterObject.query?.values.compactMap({$0.string}) {
      queryArray = Array(queryList)
    }
    
    var sortBy : [String:String]? = nil
    if let sortObject = filterObject.sort {
      var sortString = sortObject.field.squashedString
      
      // TODO, assuming dynamic fields has been made
      // need to come back to this asap
      if sortObject.field.type == "text" {
        sortString = sortString + ".keyword"
      }
      sortBy = [sortString:sortObject.order.rawValue]
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
    let settingsManager = SettingsDataManager()
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
  
  
  public static func getFields(input:String) -> [SquashedFieldsArray] {
    
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
    
    return Fields.makeSquashedArray(key: "", fields: headersDictionary, squashedArray: [SquashedFieldsArray]() )
  }
  
  // Takes all of the elastic objects
  static func _loopFields(_source: [String: Any], headersDictionary: [FieldsArray]) -> [FieldsArray] {
    
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
        local = innerFields(key:item.key, items: field,  
                            fieldsDictionary: local!)
      }
      else if let field = item.value as? [Any] {
        local = innerFields(key:item.key, items: field,
                            fieldsDictionary: local!)
      }
    
      
      // Remove any references to the existing object
      localCopy.removeAll(where: {$0.name == item.key})
      
      // Append an updated version
      localCopy.append(local!)
      
    }
    
    return localCopy
    
  }
  
  static func loopFields(_source: [String: Any], headersDictionary: [FieldsArray]) -> [FieldsArray] {
      var localCopy = Dictionary(uniqueKeysWithValues: headersDictionary.map { ($0.name, $0) })

      for item in _source {
          var local = localCopy[item.key] ?? FieldsArray(name: item.key, values: [FieldsArray]())

          if let field = item.value as? [String: Any] {
              local = innerFields(key: item.key, items: field, fieldsDictionary: local)
          } else if let field = item.value as? [Any] {
              local = innerFields(key: item.key, items: field, fieldsDictionary: local)
          }

          localCopy[item.key] = local
      }

      return Array(localCopy.values)
  }

  
  private static func innerFields(key: String, items: [Any], fieldsDictionary: FieldsArray) -> FieldsArray {
    
    var localCopy = fieldsDictionary
    
    // Loop the inner values
    for item in items {
      
      if let field = item as? [String: Any] {
        localCopy = innerFields(key: key, items: field, fieldsDictionary: fieldsDictionary)
      } else if let field = item as? [Any] {
        localCopy = innerFields(key: key, items: field, fieldsDictionary: fieldsDictionary)
      }
      
    }
    
    return localCopy
  }
  
  static func innerFields(key: String, items: [String: Any], fieldsDictionary: FieldsArray) -> FieldsArray {
      var localCopy = fieldsDictionary

      var valuesDictionary = Dictionary(uniqueKeysWithValues: (localCopy.values ?? []).map { ($0.name, $0) })

      for item in items {
          var fieldObj = valuesDictionary[item.key] ?? FieldsArray(name: item.key, values: [FieldsArray]())

          if item.value is String || item.value is Double || item.value is [String] || item.value is [Double] {
              valuesDictionary[item.key] = fieldObj
          } else if let field = item.value as? [String: Any] {
              valuesDictionary[item.key] = innerFields(key: item.key, items: field, fieldsDictionary: fieldObj)
          } else if let field = item.value as? [Any] {
              valuesDictionary[item.key] = innerFields(key: item.key, items: field, fieldsDictionary: fieldObj)
          }
      }

      localCopy.values = Array(valuesDictionary.values)
      return localCopy
  }

  
  static func _innerFields(key: String, items: [String: Any], fieldsDictionary: FieldsArray) -> FieldsArray {
    
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
      } else if let field = item.value as? [Any] {
        // if it's not a string, call the same function to pull out it's values
        // and append them
        localCopy.values?.removeAll(where: {$0.name == item.key})
        localCopy.values?.append(innerFields(key: item.key, items: field, fieldsDictionary: fieldObj!))
      }
    }
    
    return localCopy
  }
  
  
}
