// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

struct GenericQueryBuilder : Codable {
	
	func Create(queries : [String],
							compound : String,
							dateField : String?,
							range : GenericQueryBuilder.Date?,
							sortBy : [String:String]? = nil) -> Root {
		
		
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
		
		
		return root
		
	}
	
	struct Root : Codable {
		
		var query: Query?
		var sort : [String: String]?
		var size: Int?
		var from: Int?
		
	}
	
	struct Query : Codable {
		
		var bool: Bool?
		
	}
	
	struct Bool : Codable {
		
		var must: [Must]? = nil
		var should: [Should]? = nil
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
	
}
