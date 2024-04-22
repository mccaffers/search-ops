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
    // Set up a temporary, in-memory Realm database for testing to ensure a clean state for each test case.
    _ = RealmManager().getRealm(inMemory: true)
  }
  
  // Evaluates the extraction of objects from a simulated ElasticSearch response and verifies the count of the items returned.
  func testObjects() async throws {
    
    // Load a predefined static JSON file that simulates an ElasticSearch response to eliminate external dependencies during tests.
    let response = try SearchOpsTests().OpenFile(filename: "response.1")
    // Extract objects using a predefined parsing method tailored for ElasticSearch response structures.
    let output = Search.getObjects(input: response)
    
    // Asserts that the number of parsed data objects is as expected, ensuring correct parsing functionality.
    let objectCount = output.data.count
    XCTAssertEqual(objectCount, 1)
    
    // Asserts that the number of hits (a specific metric relevant to ElasticSearch) retrieved matches the expected count.
    let hitsCount = Fields.getHits(input: response)
    XCTAssertEqual(hitsCount, 1)
  }
  

  // Evaluates the integration of multiple parsing methods to render objects based on the fields extracted from a response.
  func testRenderingObjects() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.3")
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
    let response = try SearchOpsTests().OpenFile(filename: "response.3")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let sortedFields = Results.SortedFieldsWithDate(input: fields)
    let viewableFields: RenderedFields = RenderedFields(fields: sortedFields)
    
    let renderedResults = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    XCTAssertEqual(renderedResults?.headers.count, 17)
  }
  
  // Tests retrieval of a specific value by key, demonstrating the use of processed data to extract specific details.
  func testGetValueForKey() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.3")
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
    let response = try SearchOpsTests().OpenFile(filename: "response.4")
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
    let response = try SearchOpsTests().OpenFile(filename: "response.5")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let sortedFields = Results.SortedFieldsWithDate(input: fields)
    let viewableFields: RenderedFields = RenderedFields(fields: sortedFields)
    
    let renderedResults = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    XCTAssertEqual(renderedResults?.headers.count, 34)
  }


}
