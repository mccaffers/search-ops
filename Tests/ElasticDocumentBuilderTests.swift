import XCTest
import Foundation
import OrderedCollections

import SwiftUI

@testable import Search_Ops

@available(iOS 13.0, *)
class ElasticDocumentBuilderTests: XCTestCase {
  
  func testWithNoHeaders() {
    let input: OrderedDictionary<String, Any> = ["name": "Test"]
    let headers: [SquashedFieldsArray] = []
    let results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil)
    XCTAssertTrue(results.isEmpty, "Results should be empty when no headers are provided")
  }
  
  func testWithHeadersButEmptyInput() {
    let input = OrderedDictionary<String, Any>()
    let array = SquashedFieldsArray(squashedString: "Name")
    array.fieldParts.append("Name")
    let headers = [array]
    let results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil)
    XCTAssertTrue(results.isEmpty, "Results should be empty when input is empty")
  }
  
  func testNormalOperation() {
    let input: OrderedDictionary<String, Any> = ["name": "Test"]
    let array = SquashedFieldsArray(squashedString: "name")
    array.fieldParts.append("name")
    let headers = [array]
    let results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil)
    XCTAssertEqual(results.count, 2, "Should return one Text view")
    // Additional checks for text content could be added here
  }
  
  func testNormalOperation2() {
    let input: OrderedDictionary<String, Any> = ["name": "Test"]
    let array = SquashedFieldsArray(squashedString: "name")
    array.fieldParts.append("name")
    let headers = [array]
    let results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 4)
    XCTAssertEqual(results.count, 1, "Should return one Text view")
    XCTAssertEqual(results[0].value, "name", "Should return one Text view")
  }
  
  func testNormalOperation3() {
    let input: OrderedDictionary<String, Any> = ["name": "Test"]
    let array = SquashedFieldsArray(squashedString: "name")
    array.fieldParts.append("name")
    let headers = [array]
    var results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 5)
    XCTAssertEqual(results.count, 2, "Should return one Text view")
    XCTAssertEqual(results[0].value, "name", "Should return one Text view")
    XCTAssertEqual(results[1].value, "T...", "Should return one Text view")
    
    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 6)
    XCTAssertEqual(results[1].value, "Te...", "Should return one Text view")
    
    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 7)
    XCTAssertEqual(results[1].value, "Tes...", "Should return one Text view")
    
    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 8)
    XCTAssertEqual(results[1].value, "Test", "Should return one Text view")
  }
  
  func createTestObject() -> OrderedDictionary<String, Any> {
      var testDictionary = OrderedDictionary<String, Any>()

      // Populating the OrderedDictionary with keys and values based on your description
      testDictionary["date"] = "2024-04-01T12:39:50.1589320+01:00"
      testDictionary["className"] = "trading_exception.TradingException"
      testDictionary["message"] = "Could not find a part of the path '/Users/ryan/dev/projects/aws/backtesting-engine/tickdata/EURUSD'."
      testDictionary["runID"] = "DEBUG"

      let innerException = [
          "hResult": Int64(-2147024893),
          "message": "Could not find a part of the path '/Users/ryan/dev/projects/aws/backtesting-engine/tickdata/EURUSD'.",
          "className": "System.IO.DirectoryNotFoundException",
          "data": [String: Any](),  // Assuming it's an empty dictionary or similar structured data
          "source": "System.Private.CoreLib",
          "stackTrace": "   at System.IO.Enumeration.FileSystemEnumerator`1.CreateDirectoryHandle(String path, Boolean ignoreNotFound)\n   at System.IO.Enumeration.FileSystemEnumerator`1.Init()\n   at System.IO.Enumeration.FileSystemEnumerable`1..ctor(String directory, FindTransform transform, EnumerationOptions options, Boolean isNormalized)\n   at System.IO.Enumeration.FileSystemEnumerableFactory.FileInfos(String directory, String expression, EnumerationOptions options, Boolean isNormalized)\n   at System.IO.DirectoryInfo.InternalEnumerateInfos(String path, String searchPattern, SearchTarget searchTarget, EnumerationOptions options)\n   at System.IO.DirectoryInfo.GetFiles(String searchPattern, EnumerationOptions enumerationOptions)\n   at backtesting_engine_ingest.Ingest.EnvironmentSetup() in /Users/ryan/dev/projects/aws/backtesting-engine/src/backtesting/Ingest/Ingest.cs:line 45\n   at backtesting_engine.TaskManager.IngestAndConsume() in /Users/ryan/dev/projects/aws/backtesting-engine/src/backtesting/TaskManager.cs:line 25\n   at backtes"
      ] as [String : Any]
      testDictionary["innerException"] = innerException
      testDictionary["stacktrace"] = [String: Any]()  // Assuming it's an empty dictionary or similar structured data
      testDictionary["hostname"] = "Ryans-MacBook-Pro.local"
      testDictionary["runIteration"] = "0"
      testDictionary["symbols"] = "\"EURUSD\""
      testDictionary["hResult"] = Int64(-2146233088)
      testDictionary["data"] = [String: Any]()  // Assuming it's an empty dictionary or similar structured data

      return testDictionary
  }
  
  // Function to create an array of SquashedFieldsArray from an OrderedDictionary
  func createHeaders(from dictionary: OrderedDictionary<String, Any>) -> [SquashedFieldsArray] {
      var headers = [SquashedFieldsArray]()
      for key in dictionary.keys {
          headers.append(SquashedFieldsArray(squashedString: key, fieldParts: [key]))
      }
      return headers
  }
  
  
  func testNormalOperationAcrossTwoObjects() {
    let input: OrderedDictionary<String, Any> = ["name": "Test", "two" : "one"]

    let headers = [SquashedFieldsArray(squashedString: "name", fieldParts: ["name"]),
                   SquashedFieldsArray(squashedString: "two", fieldParts: ["two"])]
    
    var results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 5)
    XCTAssertEqual(results.count, 2)
    XCTAssertEqual(results[0].value, "name")
    XCTAssertEqual(results[1].value, "T...")
    
    // name Test two one = 15 characters input
    
    // Test Results
    // name Test = 10 characters (actually 8)
    // name Test = 11 characters (actually 8)
    // name Test two o... = 12 characters (actually 15)
    // name Test two o... = 12 characters (actually 15)
    
    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 10)
    XCTAssertEqual(results.count, 2)
    XCTAssertEqual(results[0].value, "name")
    XCTAssertEqual(results[1].value, "Test")
    
    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 11)
    XCTAssertEqual(results.count, 3)
    XCTAssertEqual(results[0].value, "name")
    XCTAssertEqual(results[1].value, "Test")
    XCTAssertEqual(results[2].value, "two")
    
    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 12)
    XCTAssertEqual(results.count, 4)
    XCTAssertEqual(results[0].value, "name")
    XCTAssertEqual(results[1].value, "Test")
    XCTAssertEqual(results[2].value, "two")
    XCTAssertEqual(results[3].value, "o...")
    
    
    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 7)
    XCTAssertEqual(results[1].value, "Tes...", "Should return one Text view")
    
    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 8)
    XCTAssertEqual(results[1].value, "Test", "Should return one Text view")
  }
  
  
  
  func testNormalOperationAcrossLargeObjects() {
    let input: OrderedDictionary<String, Any> = createTestObject()

    let headers = createHeaders(from: input)
    
    var results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 5)
    XCTAssertEqual(results.count, 2)

    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 200)
    XCTAssertEqual(results[7].value, "DEBUG")

    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 190)
    XCTAssertEqual(results[5].value, "Could not find a part of the path \'/Users/ryan/dev/projects/aws/backtesting-engine/tickdata/EURUSD\'.")
    
    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 195)
    XCTAssertEqual(results[7].value, "DEB...")
    
    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 100)
    XCTAssertEqual(results[5].value, "Could not ...")
    
    results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 85)
    XCTAssertEqual(results.count, 5)
    XCTAssertEqual(results[3].value, "trading_exception.TradingException")
    XCTAssertEqual(results[4].value, "me...")
    // name Test two one = 15 characters input
  
  }
  
  
  func testTruncation() {
    let input: OrderedDictionary<String, Any> = [ "name": "Test",
                                                  "count1" : "abc",
                                                  "count2" : "abc",
                                                  "count3" : "abc",
                                                  "count4" : "abc",
                                                  "count5" : "abc",
                                                  "count6" : "abc",
                                                  "count7" : "abc",
                                                  "count8" : "abc",
                                                  "count9" : "abc",
                                                  "count10" : "abc"]
    let array = SquashedFieldsArray(squashedString: "name")
    array.fieldParts.append("name")
    let headers = [array]
    
    let results = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil)
    XCTAssertEqual(results.count, 2, "Should return one Text view as there is only one correct field")
  }
  
//  func testLargeObject() {
//    let input: OrderedDictionary<String, Any> = [ "name": "Test",
//                                                  "count1" : "abc",
//                                                  "count2" : "abc",
//                                                  "count3" : "abc",
//                                                  "count4" : "abc",
//                                                  "count5" : "abc",
//                                                  "count6" : "abc",
//                                                  "count7" : "abc",
//                                                  "count8" : "abc",
//                                                  "count9" : "abc",
//                                                  "count10" : "abc",
//                                                  "count11" : "abc",
//                                                  "count12" : "abc",
//                                                  "count13" : "abc",
//                                                  "count14" : "abc",
//    ]
//
//    let headers = [SquashedFieldsArray(squashedString: "name", fieldParts: ["name"]),
//                   SquashedFieldsArray(squashedString: "count1", fieldParts: ["count1"]),
//                   SquashedFieldsArray(squashedString: "count2", fieldParts: ["count2"]),
//                   SquashedFieldsArray(squashedString: "count3", fieldParts: ["count3"]),
//                   SquashedFieldsArray(squashedString: "count4", fieldParts: ["count4"]),
//                   SquashedFieldsArray(squashedString: "count5", fieldParts: ["count5"]),
//                   SquashedFieldsArray(squashedString: "count6", fieldParts: ["count6"]),
//                   SquashedFieldsArray(squashedString: "count7", fieldParts: ["count7"]),
//                   SquashedFieldsArray(squashedString: "count8", fieldParts: ["count8"]),
//                   SquashedFieldsArray(squashedString: "count9", fieldParts: ["count9"]),
//                   SquashedFieldsArray(squashedString: "count10", fieldParts: ["count10"]),
//                   SquashedFieldsArray(squashedString: "count11", fieldParts: ["count11"]),
//                   SquashedFieldsArray(squashedString: "count12", fieldParts: ["count12"]),
//                   SquashedFieldsArray(squashedString: "count13", fieldParts: ["count13"]),
//                   SquashedFieldsArray(squashedString: "count14", fieldParts: ["count14"]),
//    ]
//    
//    let defaultResults = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil)
//    XCTAssertEqual(defaultResults.count, 22, "Should return one Text view as there is only one correct field")
//    
//    let largerResults = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil, maxCount: 15)
//    XCTAssertEqual(largerResults.count, 30, "Should return one Text view as there is only one correct field")
//  }
  
  
  // More tests following similar patterns
}
