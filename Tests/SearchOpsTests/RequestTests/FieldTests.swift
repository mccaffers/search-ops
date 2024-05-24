//
//  FieldTests.swift
//  
//
//  Created by Ryan McCaffery on 23/05/2024.
//

import XCTest

@testable import SearchOps

// Indicates that this test class is only to be used with iOS 16.0.0 and above.
@available(iOS 16.0.0, *)
final class FieldTests: XCTestCase {

    func testExample() throws {
      let testDictionary: [String: Any] = [
          "date": "2022-11-19T16:06:02.294Z",
          "url": "https://api.geo.dev/search",
          "path": "/search",
          "env": "DEVELOPMENT",
          "body": [
              "term": "London"
          ],
          "headers": [
              "accept-encoding": "gzip",
              "accept": "application/json"
          ]
      ]
      
      
      var timer = DispatchTime.now() // <<<<<<<<<< Start time
      
      var headersDictionary =  [FieldsArray]()
      headersDictionary = Fields._loopFields(_source: testDictionary, headersDictionary: headersDictionary)
      
      var timerEnd = DispatchTime.now()   // <<<<<<<<<<   end time
      var timerNanoTime = timerEnd.uptimeNanoseconds - timer.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
      var timerTimeInterval = (Double(timerNanoTime) / 1_000_000_000) * 1000000 // Technically could overflow for long running tests
      
      print(headersDictionary.count, timerTimeInterval)
      
      
      var timer2 = DispatchTime.now() // <<<<<<<<<< Start time
      
      var headersDictionary2 =  [FieldsArray]()
      headersDictionary2 = Fields.loopFields(_source: testDictionary, headersDictionary: headersDictionary2)
      
      var timerEnd2 = DispatchTime.now()   // <<<<<<<<<<   end time
      var timerNanoTime2 = timerEnd2.uptimeNanoseconds - timer2.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
      var timerTimeInterval2 = (Double(timerNanoTime2) / 1_000_000_000) * 1000000 // Technically could overflow for long running tests
      
      print(headersDictionary2.count, timerTimeInterval2)
      
      
    }
  
  func testExample2() throws {
    let testDictionary: [String: Any] = [
        "date": "2022-11-19T16:06:02.294Z",
        "url": "https://api.geo.dev/search",
        "path": "/search",
        "env": "DEVELOPMENT",
        "body": [
            "term": "London"
        ],
        "headers": [
            "accept-encoding": "gzip",
            "accept": "application/json"
        ]
    ]
    
    
    var timer = DispatchTime.now() // <<<<<<<<<< Start time
    
    var local = FieldsArray(name: "headers", values: [FieldsArray]())
    var output = Fields._innerFields(key: "headers", items: testDictionary, fieldsDictionary: local)
    
    var timerEnd = DispatchTime.now()   // <<<<<<<<<<   end time
    var timerNanoTime = timerEnd.uptimeNanoseconds - timer.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    var timerTimeInterval = (Double(timerNanoTime) / 1_000_000_000) * 1000000 // Technically could overflow for long running tests
    
    print(output.values?.count, timerTimeInterval)
    
 var timer2 = DispatchTime.now() // <<<<<<<<<< Start time
  
    var local2 = FieldsArray(name: "headers", values: [FieldsArray]())
    var output2 = Fields.innerFields(key: "headers", items: testDictionary, fieldsDictionary: local2)

    var timerEnd2 = DispatchTime.now()   // <<<<<<<<<<   end time
    var timerNanoTime2 = timerEnd2.uptimeNanoseconds - timer2.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    var timerTimeInterval2 = (Double(timerNanoTime2) / 1_000_000_000) * 1000000 // Technically could overflow for long running tests
    
    print(output2.values?.count, timerTimeInterval2)
    
    
  }
  

 

}
