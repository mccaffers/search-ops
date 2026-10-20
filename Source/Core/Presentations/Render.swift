// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

// Ensures compatibility with macOS 13 and iOS 16 and later versions.
@available(macOS 13, *)
@available(iOS 16, *)
public class SearchRender {
  
  // Asynchronously performs a search query against an Elasticsearch server using specified parameters.
  // Utilizes the `MainActor` to ensure any UI updates from the result are thread-safe.
  // `size` asks for that many documents instead of the page size set in Settings.
  @MainActor
  public static func call(pageInput: Int,
                          filterObject: FilterObject,
                          host: HostDetails,
                          index: String,
                          limitObj: LimitObj,
                          histogram: SearchHistogramRequest? = nil,
                          size: Int? = nil) async -> RenderResult {
    
    let renderResult = RenderResult() // Initialize the structure to hold search results.
    
    // Calculate the 'from' parameter for pagination: start from 0 or calculate based on page number and size.
    let from = pageInput == 0 ? 0 : ((pageInput - 1) * limitObj.size)
    
    // Execute the query with specified filters, host details, index, and pagination offset.
    var response = await Fields.QueryElastic(filterObject: filterObject,
                                              item: host,
                                              selectedIndex: index,
                                              from: from,
                                              histogram: histogram,
                                              size: size)
    
    // Read each response once, away from the main thread, and use it for the histogram check,
    // the documents and the histogram
    var parsed = await parse(response, histogram: histogram)

    // A histogram the server can't build shouldn't stop the search, so ask again without it
    if let histogram = histogram, failedOnHistogram(parsed, field: histogram.field) {
      response = await Fields.QueryElastic(filterObject: filterObject,
                                           item: host,
                                           selectedIndex: index,
                                           from: from,
                                           size: size)
      parsed = await parse(response, histogram: nil)
    }
    
    renderResult.duration = response.duration

    var hitCount : Int = 0 // Initialize the counter for hits returned by the query.
    
    // Handle potential errors in the query response.
    if let error = response.error {
      renderResult.error = error
    } else if let parsed = parsed {
      // If data is successfully parsed, process it to extract search results.
      let parsedResponse = parsed.result
      
      // Check and handle errors from data parsing.
      if let error = parsedResponse.error {
        let generatedError = ResponseError(title: parsedResponse.errorTitle ?? "Query Error",
                                           message: error,
                                           type: .critical)
        renderResult.error = generatedError
        response.error = generatedError
      } else {
        // Store the successfully parsed data and additional information in the result structure.
        renderResult.results = parsedResponse.data
        renderResult.hits = parsedResponse.hitCount // Fields.getHits(input: data)
        renderResult.hitsIsLowerBound = parsedResponse.hitCountIsLowerBound
        hitCount = renderResult.hits
        renderResult.fields = parsedResponse.fields // Fields.getFields(input: data)
        renderResult.rows = parsedResponse.rows
        renderResult.refs = parsedResponse.refs
        renderResult.pages = Results.CalculatePages(hits: renderResult.hits, limit: limitObj.size)
        if let histogram = histogram {
          renderResult.histogram = parsed.histogram
        }
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
  
  /// A search response read once: its JSON, and the documents, fields, histogram or error found in it.
  /// It's built by `read` away from the main thread and handed over once it's finished. Nothing changes it
  /// after that, which is what makes sending it between threads safe.
  struct ParsedSearch: @unchecked Sendable {
    let json: [String: Any]?
    let result: SearchResult
    let histogram: SearchHistogram?
  }

  /// Reads a response that came back without a request error, or nil when there's nothing to read.
  @MainActor
  static func parse(_ response: ServerResponse, histogram: SearchHistogramRequest?) async -> ParsedSearch? {
    guard response.error == nil, let body = response.parsed else { return nil }
    return await read(body, histogram: histogram)
  }

  /// Parses a response body and flattens its documents. A page of wide documents can take hundreds of
  /// milliseconds, so this runs away from the main thread.
  static func read(_ body: String, histogram: SearchHistogramRequest?) async -> ParsedSearch {
#if DEBUG
    dispatchPrecondition(condition: .notOnQueue(.main))
#endif
    let json = JsonTools.serialiseJson(body)
    return ParsedSearch(json: json,
                        result: Search.getObjects(json: json, input: body),
                        histogram: histogram.flatMap { SearchHistogram.parse(json: json, request: $0) })
  }

  /// Whether the server rejected a search because of its histogram aggregation on `field`.
  static func failedOnHistogram(_ parsed: ParsedSearch?, field: String) -> Bool {
    guard let parsed = parsed, parsed.result.error != nil else { return false }
    return SearchHistogram.isHistogramError(json: parsed.json, field: field)
  }
  
}
