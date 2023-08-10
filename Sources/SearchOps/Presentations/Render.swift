// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

@available(iOS 16, *)
public class SearchRender {
  
  @MainActor
  public static func call(pageInput: Int,
                          filterObject: FilterObject,
                          host: HostDetails,
                          index: String,
                          limitObj: LimitObj) async -> RenderResult {
    
    
    let renderResult = RenderResult()
    
    // Starts off at 0, but as the page incerases we need to multiply the page - 1 by the size (limit)
    let from = pageInput == 0 ? 0 : ((pageInput - 1) * limitObj.size)
    
    // Query Search
    let response = await Fields
      .QueryElastic(filterObject: filterObject,
                    item: host,
                    selectedIndex: index,
                    from:from)
    
    let responseJSON : String = ""
    var hitCount : Int = 0
    
    if let error = response.error {
      renderResult.error = error
      
    } else if let data = response.parsed {
      
      let parsedResponse = Search.getObjects(input: data)
      
      if let error = parsedResponse.error {
        let generatedError = ResponseError(title: "query_shard_exception",
                                           message: error,
                                           type: .critical)
        
        renderResult.error = generatedError
        response.error = generatedError
        
      }  else {
        renderResult.results = parsedResponse.data
        renderResult.hits = Fields.getHits(input: data)
        hitCount = renderResult.hits
        renderResult.fields = Fields.getFields(input: data)
        renderResult.pages = Results.CalculatePages(hits: renderResult.hits, limit: limitObj.size)
        
      }
    }
    
    Logger.event(response: response,
                 index: index,
                 host: host,
                 filterObject: filterObject,
                 page:pageInput,
                 hitCount: hitCount)
    
    
    return renderResult
  }
  
}
