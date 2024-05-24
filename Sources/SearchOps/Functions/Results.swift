// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import Foundation
import OrderedCollections

@available(macOS 13.0, *)
@available(iOS 15.0, *)
public class Results {
  
  // Takes a mutlti-dimensional array and returns a RenderedObject
  // Extracts all the fields out of the results
  // This is different to _mapping, as it captures fields that are not mapped
  public static func UpdateResults(searchResults : [[String: Any]]?, resultsFields:  RenderedFields) -> RenderObject? {
    
    var myArray = [OrderedDictionary<String, Any>]()
    if let searchResults = searchResults {
      for item in searchResults {
        myArray.append(OrderedDictionary(uniqueKeys: item.keys, values: item.values))
      }
      
      return RenderObject(headers: resultsFields.fields.filter({$0.visible == true}),
                          results: myArray)
      
    }
    
    
    return nil
    
  }
  public static func UpdateResultsWithFlatArray(searchResults: [[String: Any]]?, resultsFields: RenderedFields) -> RenderObject? {
      guard let searchResults = searchResults else {
          return nil
      }

      var myArray = [OrderedDictionary<String, Any>]()
      var flatArray = [OrderedDictionary<String, Any>]()

      for item in searchResults {
          let orderedItem = OrderedDictionary(uniqueKeys: item.keys, values: item.values)
          myArray.append(orderedItem)

          var flat = OrderedDictionary<String, Any>()
          for header in resultsFields.fields {
              let values = Results.getValueForKey(fieldParts: header.fieldParts, item: orderedItem)
              if !values.isEmpty {
                  flat[header.squashedString] = values
              }
          }
          flatArray.append(flat)
      }

      return RenderObject(
          headers: resultsFields.fields.filter { $0.visible },
          results: myArray,
          flat: flatArray
      )
  }


  
  // Takes a mutlti-dimensional array and returns a RenderedObject
  // Extracts all the fields out of the results
  // This is different to _mapping, as it captures fields that are not mapped
  public static func _UpdateResultsWithFlatArray(searchResults : [[String: Any]]?, resultsFields:  RenderedFields) -> RenderObject? {
    
    var myArray = [OrderedDictionary<String, Any>]()
    var flat = OrderedDictionary<String, Any>()
    var flatArray = [OrderedDictionary<String, Any>()]
    
    if let searchResults = searchResults {
      for item in searchResults {
        myArray.append(OrderedDictionary(uniqueKeys: item.keys, values: item.values))
        
        for header in resultsFields.fields {
          let values = Results.getValueForKey(fieldParts: header.fieldParts,
                                              item: convertToOrderedDictionary(item))
          
//            var flat : [String:String] = [:]
//          
          flat[header.squashedString] = values
//          flat.append(OrderedDictionary(uniqueKeys: header.squashedString, values:values))
          
        }
        flatArray.append(flat)
        flat = OrderedDictionary<String, Any>()
      }
      
      

      
      return RenderObject(headers: resultsFields.fields.filter({$0.visible == true}),
                          results: myArray,
                          flat: flatArray)
      
    }
    
    
    return nil
    
  }
  
  // Function to convert [String: Any] to OrderedDictionary<String, Any>
  static func convertToOrderedDictionary(_ dictionary: [String: Any]) -> OrderedDictionary<String, Any> {
      var orderedDict = OrderedDictionary<String, Any>()
      for (key, value) in dictionary {
          orderedDict[key] = value
      }
      return orderedDict
  }

  
  
  // Loop through all the inner objects of the results
  private static func loopInnerObjects(item: SquashedFieldsArray, level: Int, input:  [[String: Any]], originalObject:[String: Any]?=nil) -> [[String : Any]] {
    
    var myArray = [[String : Any]]()
    
    for resultObjects in input {
      for key in Array(resultObjects.keys) {
        if item.fieldParts[level] == key {
          let innerObject = resultObjects[key]
          
          var returnObj = resultObjects
          if originalObject != nil {
            returnObj = originalObject!
          }
          
          if innerObject is String {
            myArray.append(originalObject!)
          } else if let finalValue = innerObject as? [String: Any] {
            myArray.append(contentsOf: loopInnerObjects(item:item,
                                                        level:level+1,
                                                        input:[finalValue],
                                                        originalObject:returnObj ))
          }
        }
      }
    }
    return myArray
  }
  
  // Extract the value for a key inside of the JSON object
  public static func getValueForKey(fieldParts:[String], item: OrderedDictionary<String, Any>) -> [String] {
    
    if fieldParts.count == 1 {
      let key = fieldParts[0]
      if let value = item[key] as? String {
        return [value]
      } else if let value = item[key] as? Double {
        return [value.string]
      } else if let value = item[key] as? Array<String> {
        return value
      } else if let value = item[key] as? Array<Double> {
        return value.compactMap { $0.string }
      }
      
    } else {
      
      let firstKey = fieldParts[0]
      
      if let innerObj = item[firstKey] as? [String: Any] {
        return checkInnerObjects(fieldParts: fieldParts, level: 1, obj: innerObj)
      } else if let innerObj = item[firstKey] as? [Any] {
        return checkInnerObjects(fieldParts: fieldParts, level: 1, obj: innerObj)
      }
    }
    
    return [""]
    
  }
  
  public static func checkIfHeaderExistsInData(headers: [SquashedFieldsArray], item: OrderedDictionary<String, Any>)
  -> Bool {
    
    if headers.count == 0 {
      return true
    }
    
    var flag = false
    
    for header in headers {
      let keys = getValueForKey(fieldParts: header.fieldParts, item: item)
      
      for output in keys {
        if !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          flag=true
        }
      }
    }
    
    return flag
    
  }
  
  public static func exportDate(dateField: [String], input: OrderedDictionary<String, Any>) -> String {
    
    let output = Results.getValueForKey(fieldParts: dateField,
                                        item:input).first
    
    return output ?? ""
  }
  
  
  
  public static func checkInnerObjects(fieldParts: [String], level: Int, obj: [String: Any]) -> [String] {
    
    //    if fieldParts.count-1 <= level {
    let key = fieldParts[level]
    
    if let innerObj = obj[key] as? [String: Any] {
      if innerObj.count == 0 {
        return [""]
      }
      return checkInnerObjects(fieldParts: fieldParts, level: level+1, obj: innerObj)
    } else if let innerObj = obj[key] as? [Any] {
      return checkInnerObjects(fieldParts: fieldParts, level: level+1, obj: innerObj)
    } else if let value = obj[key] as? String {
      return [value]
    } else if let value = obj[key] as? Double {
      return [value.string]
    } else if let value = obj[key] as? Array<String> {
      return value
    } else if let value = obj[key] as? Array<Double> {
      return value.compactMap { $0.string }
    }
    //    }
    
    return [""]
  }
  
  public static func checkInnerObjects(fieldParts: [String], level: Int, obj: [Any]) -> [String] {
    
    var holder = [String]()
    
    for item in obj {
      if let innerObj = item as? [String: Any] {
        holder.append(contentsOf: checkInnerObjects(fieldParts: fieldParts, level: level, obj: innerObj))
      } else if let innerObj = item as? [Any] {
        holder.append(contentsOf: checkInnerObjects(fieldParts: fieldParts, level: level+1, obj: innerObj))
      }
      //    }
    }
    
    return holder
  }
  
  
  public static func SortedFieldsWithDate(input: [SquashedFieldsArray]) ->  [SquashedFieldsArray] {
    
    var sortedArray : [SquashedFieldsArray] = [SquashedFieldsArray] ()
    var nonDateFieldsForAlphaSort : [SquashedFieldsArray] = [SquashedFieldsArray] ()
    // update results immediately
    
    for item in input{
      
      item.visible = true
      
      // TODO need a better way of doing this
      if item.squashedString == "date" {
        sortedArray.append(item)
      } else {
        nonDateFieldsForAlphaSort.append(item)
      }
    }
    
    nonDateFieldsForAlphaSort.sort { $0.squashedString < $1.squashedString}
    sortedArray.append(contentsOf: nonDateFieldsForAlphaSort)
    return sortedArray
  }
  
  public static func SortedFieldsWithDateImproved(input: [SquashedFieldsArray]) -> [SquashedFieldsArray] {
      // Update all items' visibility
      input.forEach { $0.visible = true }
      
      // Partition the array into date fields and non-date fields
      var nonDateFields = input
      let dateFields = nonDateFields.filter { $0.squashedString == "date" }
      
      // Sort the non-date fields alphabetically
      nonDateFields.sort { $0.squashedString < $1.squashedString }
      
      // Combine date fields and sorted non-date fields
    return dateFields + nonDateFields
  }

  
  public static func CalculatePages(hits: Int, limit: Int) -> Int {
    var pages = Double(hits)/Double(limit)
    pages = pages.rounded(.up)
    return Int(pages)
  }
  
  public static func getIndexArray(_ input: String) -> IndexResult {
    
    let result = IndexResult()
    
    if let json = JsonTools.serialiseJson(input) {
      
      if let errorMessage = json["error"] as? [String: Any] {
        
        if let errorItems = errorMessage["root_cause"] as? [[String: Any]] {
          
          for error in errorItems {
            if let reasonString = error["reason"] as? String {
              result.error = reasonString
            }
          }
        }
        
      }
      
      for item in json {
        if !item.key.starts(with: ".") {
          result.data.append(item.key)
        }
        
      }
      
    }
    
    return result
    
    
  }
}
