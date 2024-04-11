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
  
  // Loop through all the inner objects of the results
  public static func loopInnerObjects(item: SquasedFieldsArray, level: Int, input:  [[String: Any]], originalObject:[String: Any]?=nil) -> [[String : Any]] {
    
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
  public static func getValueForKey(fieldParts:[String], item: OrderedDictionary<String, Any>) -> String {
    
    if fieldParts.count == 1 {
      let key = fieldParts[0]
      if let value = item[key] as? String {
        return value
      } else if let value = item[key] as? Double {
        return value.string
      } else if let value = item[key] as? Array<String> {
        return "[" + value.joined(separator: ", ") + "]"
      } else if let value = item[key] as? Array<Double> {
        return "[" +  value.compactMap { $0.string }.joined(separator: ",") + "]"
      }
      
    } else {
      
      let firstKey = fieldParts[0]
      
      if let innerObj = item[firstKey] as? [String: Any] {
        
        return checkInnerObjects(fieldParts: fieldParts, level: 1, obj: innerObj)
        
      }
    }
    
    return " "
    
  }
  
  public static func checkIfHeaderExistsInData(headers: [SquasedFieldsArray], item: OrderedDictionary<String, Any>)
  -> Bool {
    
    if headers.count == 0 {
      return true
    }
    
    var flag = false
    
    for header in headers {
      let output = getValueForKey(fieldParts: header.fieldParts, item: item)
      
      if !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        flag=true
      }
    }
    
    return flag
    
  }
  
  public static func exportDate(dateField: [String], input: OrderedDictionary<String, Any>) -> String {
    
    let output = Results.getValueForKey(
      fieldParts: dateField,
      item:input)
    
    return output
  }
  
  
  
  public static func checkInnerObjects(fieldParts: [String], level: Int, obj: [String: Any]) -> String {
    
    if fieldParts.count <= level {
      let key = fieldParts[level]
      
      if let innerObj = obj[key] as? [String: Any] {
        return checkInnerObjects(fieldParts: fieldParts, level: level+1, obj: innerObj)
      } else if let value = obj[key] as? String {
        return value
      } else if let value = obj[key] as? Double {
        return value.string
      } else if let value = obj[key] as? Array<String> {
        return "[" + value.joined(separator: ", ") + "]"
      } else if let value = obj[key] as? Array<Double> {
        return "[" +  value.compactMap { $0.string }.joined(separator: ",") + "]"
      }
    }
    
    return " "
  }
  
  public static func SortedFieldsWithDate(input: [SquasedFieldsArray]) ->  [SquasedFieldsArray] {
    var sortedArray : [SquasedFieldsArray] = [SquasedFieldsArray] ()
    var nonDateFieldsForAlphaSort : [SquasedFieldsArray] = [SquasedFieldsArray] ()
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
  
  public static func CalculatePages(hits: Int, limit: Int) -> Int {
    var pages = Double(hits)/Double(limit)
    pages = pages.rounded(.up)
    return Int(pages)
  }
  
  public static func getIndexArray(_ input: String) -> IndexResult {
    
    var result = IndexResult()
    
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
