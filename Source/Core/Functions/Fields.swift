// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
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
  
  
  @available(macOS 13.0, *)
  @available(iOS 16.0.0, *)
  @MainActor
  public static func QueryElastic(filterObject: FilterObject,
                                  item: HostDetails?,
                                  selectedIndex: String,
                                  from: Int = 0,
                                  histogram: SearchHistogramRequest? = nil,
                                  size: Int? = nil) async -> ServerResponse {
    
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
      var sortString = sortObject.field.squashedString.trimmingCharacters(in: .whitespacesAndNewlines)
      
      // TODO, assuming dynamic fields has been made
      // need to come back to this asap
      if sortObject.field.type == "text" {
        sortString = sortString + ".keyword"
      }
      if !sortString.isEmpty {
        sortBy = [sortString:sortObject.order.rawValue]
      }
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
                                           sortBy: sortBy,
                                           filters: filterObject.fieldFilters)
    // Documents per page from Settings, unless the caller wants another number, eg. a dashboard panel
    searchObject.size = size ?? SettingsDataManager().documentsPerPage
    searchObject.from = from
    if let histogram = histogram {
      searchObject.aggs = SearchHistogram.aggregation(histogram)
    }
    
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
    guard let jsonObj = JsonTools.serialiseJson(input),
          let hits = jsonObj["hits"] as? [String: Any],
          let documents = hits["hits"] as? [[String: Any]] else {
      return []
    }

    let sources = documents.compactMap { $0["_source"] as? [String: Any] }
    return DocumentFlattener.flattenPage(sources).fields.map {
      SquashedFieldsArray(squashedString: $0.key, fieldParts: $0.parts)
    }
  }

}
