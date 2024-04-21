// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON
import RealmSwift

@testable import SearchOps

@available(iOS 16.0.0, *)
final class ElasticSearchV8ResponseTests: XCTestCase {
  
  @MainActor
  override func setUp() {
    // Initializes an in-memory Realm database to ensure each test is performed with a clean state.
    _ = RealmManager().getRealm(inMemory: true)
  }
  
  // Tests the basic functionality of retrieving objects from an ElasticSearch response and counts the items returned.
  func testObjects() async throws {
    // Loads a static file, mimicking an ElasticSearch response, to avoid dependencies on external data during tests.
    let response = try! SearchOpsTests().OpenFile(filename: "response.1")
    // Parses objects from the response using a specific function designed to read and interpret these data structures.
    let output = Search.getObjects(input: response)
    
    // Verifies that the number of data objects parsed matches expected values.
    let objectCount = output.data.count
    XCTAssertEqual(objectCount, 1)
    
    // Verifies that the number of hits parsed (an Elasticsearch-specific metric) is as expected.
    let hitsCount = Fields.getHits(input: response)
    XCTAssertEqual(hitsCount, 1)
  }
  
  // Tests the retrieval and counting of fields within an ElasticSearch response.
  func testFields() async throws {
    let response = try! SearchOpsTests().OpenFile(filename: "response.1")
    let output = Fields.getFields(input: response)
  
    XCTAssertEqual(output.count, 7)
  }
  
  // Similar to testFields, but for a different response potentially containing more complex or nested data structures.
  func testFieldsWithDepth() async throws {
    let response = try! SearchOpsTests().OpenFile(filename: "response.2")
    let output = Fields.getFields(input: response)
    
    XCTAssertEqual(output.count, 8)
  }
  
  // Tests parsing fields when the response includes arrays, which can complicate parsing logic.
  func testFieldsWithArray() async throws {
    let response = try! SearchOpsTests().OpenFile(filename: "response.3")
    let output = Fields.getFields(input: response)
    
    XCTAssertEqual(output.count, 17)
  }
  
  // Tests the handling of large nested objects within a response, a common challenge in parsing complex JSON data.
  func testFieldsWithLargeNestedObject() async throws {
    let response = try! SearchOpsTests().OpenFile(filename: "response.6")
    let output = Fields.getFields(input: response)
    
    XCTAssertEqual(output.count, 26)
  }
  
  // Evaluates the integration of multiple parsing methods to render objects based on the fields extracted from a response.
  func testRenderingObjects() async throws {
    let response = try! SearchOpsTests().OpenFile(filename: "response.3")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    // Demonstrates combining multiple steps in processing: sorting fields, rendering them, and then updating the results with these fields.
    let viewableFields: RenderedFields = RenderedFields(fields: [SquasedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    let output = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    // Ensures that the final rendered output meets expected criteria for size and content.
    XCTAssertEqual(output!.results.count, 1)
    XCTAssertEqual(output!.results[0].count, 13)
    XCTAssertEqual((output!.results[0]["boundings"] as! [String : Any]).count, 4)
    XCTAssertEqual((output!.results[0]["location"] as! [String : Any]).count, 2)
  }
  
  // Verifies that headers are extracted and sorted correctly from the processed fields.
  func testHeaders() async throws {
    let response = try! SearchOpsTests().OpenFile(filename: "response.3")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let sortedFields = Results.SortedFieldsWithDate(input: fields)
    let viewableFields: RenderedFields = RenderedFields(fields: sortedFields)
    
    let renderedResults = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    XCTAssertEqual(renderedResults?.headers.count, 17)
  }
  
  // Tests retrieval of a specific value by key, demonstrating the use of processed data to extract specific details.
  func testGetValueForKey() async throws {
    let response = try! SearchOpsTests().OpenFile(filename: "response.3")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let viewableFields: RenderedFields = RenderedFields(fields: [SquasedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    let renderedObjects = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    let nameField = renderedObjects!.headers.first(where: {$0.squashedString == "name"})
    
    let output = Results.getValueForKey(fieldParts: nameField!.fieldParts, item: renderedObjects!.results[0])
    
    XCTAssertEqual(output, "Brighton")
  }
  
  // Verifies correct retrieval of values from arrays within the parsed fields, addressing complexities in JSON array handling.
  func testGetArrayValue() async throws {
    let response = try! SearchOpsTests().OpenFile(filename: "response.4")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let viewableFields: RenderedFields = RenderedFields(fields: [SquasedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    let renderedObjects = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    var nameField = renderedObjects!.headers.first(where: {$0.squashedString == "array"})
    
    var output = Results.getValueForKey(fieldParts: nameField!.fieldParts, item:renderedObjects!.results[0])
    
    XCTAssertEqual(output, "[test]")
    
    nameField = renderedObjects!.headers.first(where: {$0.squashedString == "two_elements"})
    
    output = Results.getValueForKey(fieldParts: nameField!.fieldParts, item:renderedObjects!.results[0])
    
    XCTAssertEqual(output, "[test, test2]")
  }
  
  // Handles the testing of very large objects to ensure robustness and correctness in handling extreme cases.
  func testLargeObject() async throws {
    let response = try! SearchOpsTests().OpenFile(filename: "response.5")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let sortedFields = Results.SortedFieldsWithDate(input: fields)
    let viewableFields: RenderedFields = RenderedFields(fields: sortedFields)
    
    let renderedResults = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    XCTAssertEqual(renderedResults?.headers.count, 34)
  }


}
