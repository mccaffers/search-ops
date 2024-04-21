// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

// Ensures compatibility with macOS 13 and iOS 16 and later versions.
@available(macOS 13, *)
@available(iOS 16, *)
public class SearchRender {
  
  // Asynchronously performs a search query against an ElasticSearch server using specified parameters.
  // Utilizes the `MainActor` to ensure any UI updates from the result are thread-safe.
  @MainActor
  public static func call(pageInput: Int,
                          filterObject: FilterObject,
                          host: HostDetails,
                          index: String,
                          limitObj: LimitObj) async -> RenderResult {
    
    let renderResult = RenderResult() // Initialize the structure to hold search results.
    
    // Calculate the 'from' parameter for pagination: start from 0 or calculate based on page number and size.
    let from = pageInput == 0 ? 0 : ((pageInput - 1) * limitObj.size)
    
    // Execute the query with specified filters, host details, index, and pagination offset.
    let response = await Fields
      .QueryElastic(filterObject: filterObject,
                    item: host,
                    selectedIndex: index,
                    from: from)
    
    var hitCount : Int = 0 // Initialize the counter for hits returned by the query.
    
    // Handle potential errors in the query response.
    if let error = response.error {
      renderResult.error = error
    } else if let data = response.parsed {
      // If data is successfully parsed, process it to extract search results.
      let parsedResponse = Search.getObjects(input: data)
      
      // Check and handle errors from data parsing.
      if let error = parsedResponse.error {
        let generatedError = ResponseError(title: "query_shard_exception",
                                           message: error,
                                           type: .critical)
        renderResult.error = generatedError
        response.error = generatedError
      } else {
        // Store the successfully parsed data and additional information in the result structure.
        renderResult.results = parsedResponse.data
        renderResult.hits = Fields.getHits(input: data)
        hitCount = renderResult.hits
        renderResult.fields = Fields.getFields(input: data)
        renderResult.pages = Results.CalculatePages(hits: renderResult.hits, limit: limitObj.size)
      }
    }
    
    // Log the event detailing the query and its outcomes for auditing and debugging purposes.
    Logger.event(response: response,
                 index: index,
                 host: host,
                 filterObject: filterObject,
                 page: pageInput,
                 hitCount: hitCount)
    
    return renderResult // Return the structured result of the query.
  }
  
}
