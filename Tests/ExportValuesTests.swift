// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

import OrderedCollections

@testable import Search_Ops

final class ExportValuesTests: XCTestCase {


    func testExample() throws {
      let data = """

{
    "took": 0,
    "timed_out": false,
    "_shards": {
        "total": 1,
        "successful": 1,
        "skipped": 0,
        "failed": 0
    },
    "hits": {
        "total": {
            "value": 1,
            "relation": "eq"
        },
        "max_score": 1.0,
        "hits": [
            {
                "_index": "geo",
                "_id": "9jOjkIQBf1RYjLM4w4JM",
                "_score": 1.0,
                "_source": {
                    "url": "https://api.geo.dev/search",
                    "path": "/search",
                    "headers": {
                        "accept": "application/json",
                        "accept-encoding": "gzip",
                    },
                    "body": {
                        "term": "London"
                    },
                    "date": "2022-11-19T16:06:02.294Z",
                    "env": "DEVELOPMENT"
                }
            }
        ]
    }
}
"""
      
      // If data is successfully parsed, process it to extract search results.
      let parsedResponse = Search.getObjects(input: data)
      let renderResult = RenderResult() // Initialize the structure to hold search results.
      // Store the successfully parsed data and additional information in the result structure.
      renderResult.results = parsedResponse.data
      renderResult.hits = Fields.getHits(input: data)
      
      XCTAssertEqual(parsedResponse.hitCount, Fields.getHits(input: data))
      renderResult.fields = Fields.getFields(input: data)
      renderResult.pages = Results.CalculatePages(hits: renderResult.hits, limit: 15)
      
      var resultsFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
      let response = renderResult
      
      let searchResults = response.results
      let hitCount = response.hits
      resultsFields.fields = response.fields ?? []
      let pageCount = response.pages
      var viewableFields: RenderedFields = RenderedFields(fields: [])
      
      
      var timer = DispatchTime.now() // <<<<<<<<<< Start time
      
      viewableFields.fields=Results.SortedFieldsWithDate(input: resultsFields.fields)
      
      var timerEnd = DispatchTime.now()   // <<<<<<<<<<   end time
      var timerNanoTime = timerEnd.uptimeNanoseconds - timer.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
      var timerTimeInterval = (Double(timerNanoTime) / 1_000_000_000) * 1000000 // Technically could overflow for long running tests
      
      print("Time to evaluate prev \(timerTimeInterval) seconds")
//      print("Time to evaluate new \(timeIntervalSimple) seconds")
//      XCTAssertEqual(viewableFields.fields.count, 7)
      
     
      timer = DispatchTime.now() // <<<<<<<<<< Start time
      
      viewableFields.fields=Results.SortedFieldsWithDateImproved(input: resultsFields.fields)
      
      timerEnd = DispatchTime.now()   // <<<<<<<<<<   end time
      timerNanoTime = timerEnd.uptimeNanoseconds - timer.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
      timerTimeInterval = (Double(timerNanoTime) / 1_000_000_000) * 1000000  // Technically could overflow for long running tests
      
      print("Imrpoved to evaluate prev \(timerTimeInterval) seconds")
      
      print("-----")
      
//      XCTAssertEqual(renderedObjects?.results.count, 1)


    
      let start = DispatchTime.now() // <<<<<<<<<< Start time
      
      let renderedObjects = Results.UpdateResults(searchResults: searchResults,
                                              resultsFields: viewableFields)

      
      var filteredFields = [SquashedFieldsArray]()
      if let renderedObjects = renderedObjects {
        let headers = filteredFields.count == 0 ? renderedObjects.headers : filteredFields
        
        //        var flat2 = OrderedDictionary<String, Any>()
        
        for var index in renderedObjects.results.indices {
          
          for var header in headers {
            let values = Results.getValueForKey(fieldParts: header.fieldParts,
                                                item: renderedObjects.results[index])
            
         
          }
          
          let myDic = ElasticDocumentBuilder.exportValues(
            input: renderedObjects.results[index],
            headers: headers,
            dateObj: FilterObject().dateField,
            maxCount:500)
//          print(myDic)
          print((myDic).map({$0.value}))
        }
        
      }
      let end = DispatchTime.now()   // <<<<<<<<<<   end time
      let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
      let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

      
      let startSimple = DispatchTime.now() // <<<<<<<<<< Start time
      
      let renderedObjectsWithFlat = Results.UpdateResultsWithFlatArray(searchResults: searchResults,
                                              resultsFields: viewableFields)
       
      let squashedField = SquashedFieldsArray(
          id: UUID(uuidString: "DB59D3BE-E908-41C7-9807-B413246876F8")!,
          squashedString: "boundings.east",
          fieldParts: ["boundings", "east"]
      )
      squashedField.type = "float"
      squashedField.index = "geo"
      squashedField.visible = true

      
      if let renderedObjectsWithFlat = renderedObjectsWithFlat {
        if let flatArray = renderedObjectsWithFlat.flat {
          for var item in flatArray {
            let myDic2 = ElasticDocumentBuilder.exportFlatValues(input: item, filteredFields: [squashedField], maxCount:500)
            print(myDic2.map({$0.value}))
          }
        }
        
        
        
      }
      
      let endSimple = DispatchTime.now()   // <<<<<<<<<<   end time
      let nanoTimeSimple = endSimple.uptimeNanoseconds - startSimple.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
      let timeIntervalSimple = Double(nanoTimeSimple) / 1_000_000_000 // Technically could overflow for long running tests
      
      var difference = timeIntervalSimple/timeInterval
      
      print("Time to evaluate prev \(timeInterval) seconds")
      print("Time to evaluate new \(timeIntervalSimple) seconds")
      print(difference)
      
    }
  
  
  func testExample2() throws {
    let data = """

{
  "took": 0,
  "timed_out": false,
  "_shards": {
      "total": 1,
      "successful": 1,
      "skipped": 0,
      "failed": 0
  },
  "hits": {
      "total": {
          "value": 1,
          "relation": "eq"
      },
      "max_score": 1.0,
      "hits": [
          {
              "_index": "geo",
              "_id": "9jOjkIQBf1RYjLM4w4JM",
              "_score": 1.0,
              "_source": {
                  "url": "https://api.geo.dev/search",
                  "path": "/search",
                  "headers": {
                      "accept": "application/json",
                      "accept-encoding": "gzip",
                  },
                  "body": {
                      "term": "London"
                  },
                  "date": "2022-11-19T16:06:02.294Z",
                  "env": "DEVELOPMENT"
              }
          }
      ]
  }
}
"""
    
    // If data is successfully parsed, process it to extract search results.
    let parsedResponse = Search.getObjects(input: data)
    let renderResult = RenderResult() // Initialize the structure to hold search results.
    // Store the successfully parsed data and additional information in the result structure.
    renderResult.results = parsedResponse.data
    renderResult.hits = Fields.getHits(input: data)
    
    XCTAssertEqual(parsedResponse.hitCount, Fields.getHits(input: data))
    renderResult.fields = Fields.getFields(input: data)
    renderResult.pages = Results.CalculatePages(hits: renderResult.hits, limit: 15)
    
    var resultsFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
    let response = renderResult
    
    let searchResults = response.results
    let hitCount = response.hits
    resultsFields.fields = response.fields ?? []
    let pageCount = response.pages
    var viewableFields: RenderedFields = RenderedFields(fields: [])
    
    viewableFields.fields=Results.SortedFieldsWithDateImproved(input: resultsFields.fields)


  
    let start = CFAbsoluteTimeGetCurrent()
    
    let renderedObjects = Results.UpdateResults(searchResults: searchResults,
                                            resultsFields: viewableFields)

    
   
   
   let renderedObjectsWithFlat2 = Results.UpdateResultsWithFlatArray(searchResults: searchResults,
                                           resultsFields: viewableFields)
   
   if let renderedObjectsWithFlat2 = renderedObjectsWithFlat2 {
     if let flatArray = renderedObjectsWithFlat2.flat {
       for var item in flatArray {
         let myDic2 = ElasticDocumentBuilder._exportFlatValues(input: item,maxCount:500)
         print(myDic2.map({$0.value}))
       }
     }
     
     
     
   }
   
    let diff = CFAbsoluteTimeGetCurrent() - start
    print("Took \(diff) seconds")
    
    let start2 = CFAbsoluteTimeGetCurrent()
    
    let renderedObjectsWithFlat = Results.UpdateResultsWithFlatArray(searchResults: searchResults,
                                            resultsFields: viewableFields)
    
    let squashedField = SquashedFieldsArray(
        id: UUID(uuidString: "DB59D3BE-E908-41C7-9807-B413246876F8")!,
        squashedString: "boundings.east",
        fieldParts: ["boundings", "east"]
    )
    squashedField.type = "float"
    squashedField.index = "geo"
    squashedField.visible = true

    
    if let renderedObjectsWithFlat = renderedObjectsWithFlat {
      if let flatArray = renderedObjectsWithFlat.flat {
        for var item in flatArray {
          let myDic2 = ElasticDocumentBuilder.exportFlatValues(input: item, filteredFields: [squashedField], maxCount:500)
          print(myDic2.map({$0.value}))
        }
      }
      
      
      
    }
    
    let diff2 = CFAbsoluteTimeGetCurrent() - start2
    print("Took \(diff2) seconds")
    
    


    
//    print(difference)
    
  }
  

  

}
