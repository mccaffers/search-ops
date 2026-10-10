// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

struct GenericQueryBuilder : Codable {
  
  func Create(queries : [String],
              compound : String,
              dateField : String?,
              range : GenericQueryBuilder.Date?,
              sortBy : [String:String]? = nil,
              filters : [FieldFilter] = []) -> Root {
    
    
    var root = Root()
    
    // SORT BY
    if let sortBy = sortBy {
      root.sort = sortBy
    }
    
    // Query String Array
    root.query = Query()
    root.query?.bool = Bool()
    
    // By default build a must array
    root.query?.bool?.must = []
    
    // if we have an OR query, we need to build up
    // an error bool array of Should objects
    var mustWrapper = Must()
    if compound == "should" {
      mustWrapper.bool = Bool()
      mustWrapper.bool?.should = []
    }
    
    // lets loop around all the query strings
    for query in queries {
      
      // Build query object for Search
      var queryStringObj = QueryString()
      queryStringObj.query = query
      
      // Build a must object if we have
      // only one query string, or multiple
      // with an AND compound
      if compound == "must" {
        var queryStringMust = Must()
        queryStringMust.query_string = queryStringObj
        
        root.query?.bool?.must?.append(queryStringMust)
      } else if compound == "should" {
        
        // if we have an OR compound (should)
        // we need to build up Should objects
        // add them to the must array wrapper
        var shouldWrap = Should()
        shouldWrap.query_string = queryStringObj
        mustWrapper.bool?.should?.append(shouldWrap)
        
      }
      
    }
    
    // Finally, if we have a OR (should) compound
    // we need to append all of the Should objects
    // this lets use Search with a Date Range (of must)
    // and Or Query Strings
    if compound == "should" {
      root.query?.bool?.must?.append(mustWrapper)
    }
    
    
    if let range = range,
       let field = dateField{
      
      var rangeMust = Must()
      rangeMust.range = [field:range]
      
      root.query?.bool?.must?.append(rangeMust)
    }
    
    // Field filters match their value as a phrase, without scoring, so the server can cache them.
    // Disabled ones are left out, and with none the request is the same as before.
    let enabledFilters = filters.enabled
    let keep = enabledFilters.filter { !$0.negated }.map(FilterClause.init)
    let exclude = enabledFilters.filter { $0.negated }.map(FilterClause.init)
    if !keep.isEmpty {
      root.query?.bool?.filter = keep
    }
    if !exclude.isEmpty {
      root.query?.bool?.must_not = exclude
    }
    
    return root
    
  }
  
  struct Root : Codable {
    
    var query: Query?
    var sort : [String: String]?
    var size: Int?
    var from: Int?
    var aggs: [String: Aggregation]?
    
  }
  
  struct Query : Codable {
    
    var bool: Bool?
    
  }
  
  struct Bool : Codable {
    
    var must: [Must]? = nil
    var should: [Should]? = nil
    var filter: [FilterClause]? = nil
    var must_not: [FilterClause]? = nil
  }
  
  struct FilterClause : Codable, Equatable {
    var match_phrase: [String: String]
    
    init(_ filter: FieldFilter) {
      match_phrase = [filter.field: filter.value]
    }
  }
  
  struct Should : Codable {
    var query_string: QueryString?
    var range: [String: GenericQueryBuilder.Date]?
  }
  
  struct Must : Codable {
    var query_string: QueryString?
    var range: [String: GenericQueryBuilder.Date]?
    var bool : Bool?
  }
  
  struct QueryString : Codable {
    var query: String?
  }
  
  struct Range : Codable {
    var date: GenericQueryBuilder.Date = GenericQueryBuilder.Date(lte: "", gte: "")
  }
  
  struct Date : Codable {
    var lte: String?
    var gte: String?
  }
  
  struct Aggregation : Codable, Equatable {
    var date_histogram: DateHistogram?
  }
  
  struct DateHistogram : Codable, Equatable {
    var field: String
    var fixed_interval: String?
    var interval: String?
    var min_doc_count: Int?
    var extended_bounds: Bounds?
    var time_zone: String?
  }
  
  struct Bounds : Codable, Equatable {
    var min: Int64
    var max: Int64
  }
  
}
