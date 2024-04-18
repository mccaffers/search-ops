// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON
import Realm

@testable import SearchOps

@available(iOS 16.0.0, *)
final class ElasticSearch_v8_ResponseTests: XCTestCase {
  
  @MainActor
  override func setUp() {
    // https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/test-and-debug/
    _ = RealmManager().getRealm(inMemory: true)
  }
  
  func testObjects() async throws {
    
    let response = try! SearchOpsTests().OpenFile(filename: "response.1")
    let output = Search.getObjects(input: response)
    
    let objectCount = output.data.count
    XCTAssertEqual(objectCount, 1)
    
    let hitsCount = Fields.getHits(input: response)
    XCTAssertEqual(hitsCount, 1)
    
  }

  func testFields() async throws {
    
    let response = try! SearchOpsTests().OpenFile(filename: "response.1")
    let output = Fields.getFields(input: response)
    
    let fieldsCount = output.count
    XCTAssertEqual(output.count, 7)
  }
  
  func testFieldsWithDepth() async throws {
    
    let response = try! SearchOpsTests().OpenFile(filename: "response.2")
    let output = Fields.getFields(input: response)
    
    let fieldsCount = output.count
    XCTAssertEqual(fieldsCount, 8)
  }
  
  func testFieldsWithArray() async throws {
    
    let response = try! SearchOpsTests().OpenFile(filename: "response.3")
    let output = Fields.getFields(input: response)
    
    let fieldsCount = output.count
    XCTAssertEqual(fieldsCount, 17)
  }
  
  func testFieldsWithLargeNestedObject() async throws {
    
    let response = try! SearchOpsTests().OpenFile(filename: "response.6")
    let output = Fields.getFields(input: response)
    
    let fieldsCount = output.count
    XCTAssertEqual(fieldsCount, 26)
  }
  
  func testRenderingObjects() async throws {
    
    let response = try! SearchOpsTests().OpenFile(filename: "response.3")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    var viewableFields: RenderedFields = RenderedFields(fields: [SquasedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    let output = Results.UpdateResults(searchResults: objects.data,
                                       resultsFields: viewableFields)
    
    XCTAssertEqual(output!.results.count, 1)
    XCTAssertEqual(output!.results[0].count, 13)
    XCTAssertEqual((output!.results[0]["boundings"] as! [String : Any]).count, 4)
    XCTAssertEqual((output!.results[0]["location"] as! [String : Any]).count, 2)
  }
  
  func testHeaders() async throws {
    
    // JSON Response
    let response = try! SearchOpsTests().OpenFile(filename: "response.3")
    
    // Serialise and extracts the JSON array from the response
    let objects = Search.getObjects(input: response)
    
    // Serialise and extracts the fields from the JSON response
    let fields = Fields.getFields(input: response)
    
    // Extract the headers and sort them
    let sortedFields = Results.SortedFieldsWithDate(input: fields)
    var viewableFields: RenderedFields = RenderedFields(fields: sortedFields)
    
    var renderedResults = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    XCTAssertEqual(renderedResults?.headers.count, 17)
  }
  
  func testGetValueForKey() async throws {
    
    // JSON Response
    let response = try! SearchOpsTests().OpenFile(filename: "response.3")
    
    // Serialise and extracts the JSON array from the response
    let objects = Search.getObjects(input: response)
    
    // Serialise and extracts the fields from the JSON response
    let fields = Fields.getFields(input: response)
    
    // Sorts the fields, put Date header at the start if it's there
    var viewableFields: RenderedFields = RenderedFields(fields: [SquasedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    // Creates an OrderedDictionary
    var renderedObjects = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    //
    // XCT Test Case - Value for field 'name'
    //
    
    var nameField = renderedObjects!.headers.first(where: {$0.squashedString == "name"})
    
    let output = Results.getValueForKey(fieldParts: nameField!.fieldParts,
                                        item:renderedObjects!.results[0])
    
    XCTAssertEqual(output, "Brighton")
  }
  
  
  func testGetArrayValue() async throws {
    
    // JSON Response
    let response = try! SearchOpsTests().OpenFile(filename: "response.4")
    
    // Serialise and extracts the JSON array from the response
    let objects = Search.getObjects(input: response)
    
    // Serialise and extracts the fields from the JSON response
    let fields = Fields.getFields(input: response)
    
    // Sorts the fields, put Date header at the start if it's there
    var viewableFields: RenderedFields = RenderedFields(fields: [SquasedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    // Creates an OrderedDictionary
    var renderedObjects = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    //
    // XCT Test Case - Value for field 'name'
    //
    
    var nameField = renderedObjects!.headers.first(where: {$0.squashedString == "array"})
    
    var output = Results.getValueForKey(fieldParts: nameField!.fieldParts,
                                        item:renderedObjects!.results[0])
    
    XCTAssertEqual(output, "[test]")
    
    nameField = renderedObjects!.headers.first(where: {$0.squashedString == "two_elements"})
    
    output = Results.getValueForKey(fieldParts: nameField!.fieldParts,
                                    item:renderedObjects!.results[0])
    
    XCTAssertEqual(output, "[test, test2]")
  }
  
  func testLargeObject() async throws {
    
    // JSON Response
    let response = try! SearchOpsTests().OpenFile(filename: "response.5")
    
    // Serialise and extracts the JSON array from the response
    let objects = Search.getObjects(input: response)
    
    // Serialise and extracts the fields from the JSON response
    let fields = Fields.getFields(input: response)
    
    // Extract the headers and sort them
    let sortedFields = Results.SortedFieldsWithDate(input: fields)
    var viewableFields: RenderedFields = RenderedFields(fields: sortedFields)
    
    var renderedResults = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    XCTAssertEqual(renderedResults?.headers.count, 34)
    
  }
}
