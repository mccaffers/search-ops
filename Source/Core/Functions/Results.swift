// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
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
  /// `refs` are where each document lives, in the same order as `searchResults`
  public static func UpdateResults(searchResults : [[String: Any]]?, resultsFields:  RenderedFields,
                                   refs: [DocumentRef?] = []) -> RenderObject? {
    
    var myArray = [OrderedDictionary<String, Any>]()
    if let searchResults = searchResults {
      for item in searchResults {
        myArray.append(OrderedDictionary(uniqueKeys: item.keys, values: item.values))
      }
      
      return RenderObject(headers: resultsFields.fields.filter({$0.visible == true}),
                          results: myArray,
                          refs: refs)
      
    }
    
    
    return nil
    
  }
  /// The results with each document flattened into a row of its fields' values, for the table.
  /// Pass `rows` when the documents were already flattened while reading the response, as `SearchResult.rows` are.
  public static func UpdateResultsWithFlatArray(searchResults: [[String: Any]]?,
                                                resultsFields: RenderedFields,
                                                datefield: SquashedFieldsArray? = nil,
                                                rows: [OrderedDictionary<String, Any>]? = nil,
                                                refs: [DocumentRef?] = []) -> RenderObject? {
      guard let searchResults = searchResults else {
          return nil
      }

      return RenderObject(
          headers: resultsFields.fields.filter { $0.visible },
          results: searchResults.map { OrderedDictionary(uniqueKeys: $0.keys, values: $0.values) },
          flat: rows ?? DocumentFlattener.flattenPage(searchResults).rows,
          dateField: datefield,
          refs: refs
      )
  }

  /// The values of a field in a document, read the same way `DocumentFlattener` reads them: through objects and
  /// every element of arrays at any depth, with keys that contain dots matched as well as nested ones.
  /// `[""]` when the document has no value for the field.
  public static func getValueForKey(fieldParts:[String], item: OrderedDictionary<String, Any>) -> [String] {
    let segments = fieldParts.joined(separator: ".").split(separator: ".", omittingEmptySubsequences: false).map(String.init)
    var values = [String]()

    var key = ""
    for end in 1...segments.count {
      key = end == 1 ? segments[0] : key + "." + segments[end - 1]
      if let child = item[key] {
        collectValues(child, segments: segments, from: end, into: &values)
      }
    }

    return values.isEmpty ? [""] : values
  }

  /// Adds the values under `value` for the field whose name is made of `segments`, from `start` onwards.
  /// A key can hold one segment, or several joined with dots, eg. `"host.name"`.
  static func collectValues(_ value: Any, segments: [String], from start: Int, into values: inout [String]) {
    if let array = value as? [Any] {
      for element in array {
        collectValues(element, segments: segments, from: start, into: &values)
      }
      return
    }

    if start == segments.count {
      if let text = DocumentFlattener.text(for: value) {
        values.append(text)
      }
      return
    }

    guard let object = value as? [String: Any] else {
      return
    }
    var key = ""
    for end in (start + 1)...segments.count {
      key = end == start + 1 ? segments[start] : key + "." + segments[end - 1]
      if let child = object[key] {
        collectValues(child, segments: segments, from: end, into: &values)
      }
    }
  }
  
  /// A field's values in one line, eg. "a, b, c", leaving out blank ones. Empty when there are none.
  public static func joinedValues(_ values: [String]) -> String {
    values.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: ", ")
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
//    nonDateFields = nonDateFields.filter { $0.squashedString != "date" }
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
      
      // Check for standard Elasticsearch error format
      if let errorMessage = json["error"] as? [String: Any] {
        if let errorItems = errorMessage["root_cause"] as? [[String: Any]] {
          for error in errorItems {
            if let reasonString = error["reason"] as? String {
              result.error = reasonString
            }
          }
        }
        if result.error == nil, let reason = errorMessage["reason"] as? String {
          result.error = reason
        }
        // Return early if there's an error to prevent processing error response fields
        return result
      }

      // Check if error is a simple string: {"error": "..."}
      if let errorString = json["error"] as? String {
        result.error = errorString
        return result
      }

      // Check for alternative error format with "message" and "ok" fields
      if let message = json["message"] as? String,
         let ok = json["ok"] as? Bool,
         ok == false {
        result.error = message
        return result
      }
      
      for item in json {
        if item.key.starts(with: ".") {
          result.hiddenData.append(item.key)
        } else {
          result.data.append(item.key)
        }
      }
      
    }
    
    return result
  }

  public static func parseIndexStats(_ input: String) -> [String: IndexStatsItem] {
    guard let json = JsonTools.serialiseJson(input) else {
      return [:]
    }

    if json["error"] != nil {
      return [:]
    }
    if let ok = json["ok"] as? Bool, !ok {
      return [:]
    }

    guard let indicesDict = (json["indices"] as? [String: Any]) ?? (json["_shards"] == nil ? json : nil) else {
      return [:]
    }

    var result: [String: IndexStatsItem] = [:]
    for (key, value) in indicesDict {
      if key.hasPrefix("_") || key == "error" || key == "status" || key == "message" {
        continue
      }
      guard let indexData = value as? [String: Any] else {
        continue
      }

      let primaries = indexData["primaries"] as? [String: Any]
      let total = indexData["total"] as? [String: Any]

      let primaryDocs = primaries?["docs"] as? [String: Any]
      let primaryStore = primaries?["store"] as? [String: Any]
      let totalDocs = total?["docs"] as? [String: Any]
      let totalStore = total?["store"] as? [String: Any]

      let primaryDocCount = (primaryDocs?["count"] as? NSNumber)?.intValue
      let totalDocCount = (totalDocs?["count"] as? NSNumber)?.intValue
      let docCount = primaryDocCount ?? totalDocCount

      let primaryStorage = (primaryStore?["size_in_bytes"] as? NSNumber)?.int64Value
      let totalStorage = (totalStore?["size_in_bytes"] as? NSNumber)?.int64Value
      let storageBytes = primaryStorage ?? totalStorage

      let deletedDocCount = (primaryDocs?["deleted"] as? NSNumber)?.intValue ?? (totalDocs?["deleted"] as? NSNumber)?.intValue

      result[key] = IndexStatsItem(
        docCount: docCount,
        storageBytes: storageBytes,
        totalDocCount: totalDocCount,
        totalStorageBytes: totalStorage,
        deletedDocCount: deletedDocCount
      )
    }

    return result
  }
}
