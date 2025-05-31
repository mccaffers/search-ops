// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON
import RealmSwift

@testable import Search_Ops

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
    let viewableFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
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
    
    let viewableFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    let renderedObjects = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    let nameField = renderedObjects!.headers.first(where: {$0.squashedString == "name"})
    
    let output = Results.getValueForKey(fieldParts: nameField!.fieldParts, item: renderedObjects!.results[0])
    
    XCTAssert(output.contains("Brighton"))
  }
  
  // Verifies correct retrieval of values from arrays within the parsed fields, addressing complexities in JSON array handling.
  func testGetArrayValue() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.4")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let viewableFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    let renderedObjects = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    var nameField = renderedObjects!.headers.first(where: {$0.squashedString == "array"})
    
    var output = Results.getValueForKey(fieldParts: nameField!.fieldParts, item:renderedObjects!.results[0])
    
    XCTAssert(output.contains("test"))
    
    nameField = renderedObjects!.headers.first(where: {$0.squashedString == "two_elements"})
    
    output = Results.getValueForKey(fieldParts: nameField!.fieldParts, item:renderedObjects!.results[0])
    
    XCTAssert(output.contains("test"))
    XCTAssert(output.contains("test2"))
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
  
  // Tests the _UpdateResultsWithFlatArray function with simple data
  func test_UpdateResultsWithFlatArray_SimpleData() async throws {
    // Create test data
    let searchResults: [[String: Any]] = [
      ["name": "Test User", "age": 30, "city": "London"],
      ["name": "Another User", "age": 25, "city": "Paris"]
    ]
    
    // Create fields
    let fields = [
      SquashedFieldsArray(squashedString: "name", fieldParts: ["name"]),
      SquashedFieldsArray(squashedString: "age", fieldParts: ["age"]),
      SquashedFieldsArray(squashedString: "city", fieldParts: ["city"])
    ]
    fields.forEach { $0.visible = true }
    
    let viewableFields = RenderedFields(fields: fields)
    
    // Test the function
    let result = Results._UpdateResultsWithFlatArray(searchResults: searchResults, resultsFields: viewableFields)
    
    // Assertions
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.results.count, 2)
    XCTAssertEqual(result?.flat?.count, 3) // Has 3 entries due to initial empty entry
    XCTAssertEqual(result?.headers.count, 3)
    
    // Check flat array content (skip first empty entry)
    if let flat = result?.flat {
      XCTAssertEqual(flat[1]["name"] as? [String], ["Test User"])
      XCTAssertEqual(flat[1]["age"] as? [String], ["30"])
      XCTAssertEqual(flat[1]["city"] as? [String], ["London"])
      
      XCTAssertEqual(flat[2]["name"] as? [String], ["Another User"])
      XCTAssertEqual(flat[2]["age"] as? [String], ["25"])
      XCTAssertEqual(flat[2]["city"] as? [String], ["Paris"])
    }
  }
  
  // Tests _UpdateResultsWithFlatArray with nested data
  func test_UpdateResultsWithFlatArray_NestedData() async throws {
    // Create nested test data
    let searchResults: [[String: Any]] = [
      [
        "user": [
          "name": "John Doe",
          "details": [
            "age": 35,
            "location": "NYC"
          ]
        ],
        "status": "active"
      ]
    ]
    
    // Create fields for nested structure
    let fields = [
      SquashedFieldsArray(squashedString: "user.name", fieldParts: ["user", "name"]),
      SquashedFieldsArray(squashedString: "user.details.age", fieldParts: ["user", "details", "age"]),
      SquashedFieldsArray(squashedString: "user.details.location", fieldParts: ["user", "details", "location"]),
      SquashedFieldsArray(squashedString: "status", fieldParts: ["status"])
    ]
    fields.forEach { $0.visible = true }
    
    let viewableFields = RenderedFields(fields: fields)
    
    // Test the function
    let result = Results._UpdateResultsWithFlatArray(searchResults: searchResults, resultsFields: viewableFields)
    
    // Assertions
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.results.count, 1)
    XCTAssertEqual(result?.headers.count, 4)
    
    // Check flat array content for nested values (skip first empty entry)
    if let flat = result?.flat {
      XCTAssertEqual(flat[1]["user.name"] as? [String], ["John Doe"])
      XCTAssertEqual(flat[1]["user.details.age"] as? [String], ["35"])
      XCTAssertEqual(flat[1]["user.details.location"] as? [String], ["NYC"])
      XCTAssertEqual(flat[1]["status"] as? [String], ["active"])
    }
  }
  
  // Tests _UpdateResultsWithFlatArray with nil/empty data
  func test_UpdateResultsWithFlatArray_EmptyData() async throws {
    let viewableFields = RenderedFields(fields: [])
    
    // Test with nil searchResults
    let resultNil = Results._UpdateResultsWithFlatArray(searchResults: nil, resultsFields: viewableFields)
    XCTAssertNil(resultNil)
    
    // Test with empty searchResults
    let resultEmpty = Results._UpdateResultsWithFlatArray(searchResults: [], resultsFields: viewableFields)
    XCTAssertNotNil(resultEmpty)
    XCTAssertEqual(resultEmpty?.results.count, 0)
    XCTAssertEqual(resultEmpty?.flat?.count, 1) // Has 1 entry due to initial empty entry
  }
  
  // Tests _UpdateResultsWithFlatArray with array values
  func test_UpdateResultsWithFlatArray_ArrayValues() async throws {
    // Create test data with arrays
    let searchResults: [[String: Any]] = [
      [
        "tags": ["swift", "ios", "development"],
        "scores": [95.5, 87.3, 92.1]
      ]
    ]
    
    // Create fields
    let fields = [
      SquashedFieldsArray(squashedString: "tags", fieldParts: ["tags"]),
      SquashedFieldsArray(squashedString: "scores", fieldParts: ["scores"])
    ]
    fields.forEach { $0.visible = true }
    
    let viewableFields = RenderedFields(fields: fields)
    
    // Test the function
    let result = Results._UpdateResultsWithFlatArray(searchResults: searchResults, resultsFields: viewableFields)
    
    // Assertions
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.results.count, 1)
    
    // Check array handling in flat structure (skip first empty entry)
    if let flat = result?.flat {
      let tags = flat[1]["tags"] as? [String]
      XCTAssertEqual(tags?.count, 3)
      XCTAssertTrue(tags?.contains("swift") ?? false)
      
      let scores = flat[1]["scores"] as? [String]
      XCTAssertEqual(scores?.count, 3)
      XCTAssertTrue(scores?.contains("95.5") ?? false)
    }
  }
  
  // Tests that indirectly test loopInnerObjects through complex nested structures
  func test_ComplexNestedStructure_IndirectlyTestsLoopInnerObjects() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.3")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let viewableFields = RenderedFields(fields: Results.SortedFieldsWithDate(input: fields))
    
    // Use _UpdateResultsWithFlatArray to indirectly test loopInnerObjects
    let result = Results._UpdateResultsWithFlatArray(searchResults: objects.data, resultsFields: viewableFields)
    
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.results.count, 1)
    
    // Verify nested boundings object was processed correctly (skip first empty entry)
    if let flat = result?.flat {
      XCTAssertNotNil(flat[1]["boundings.west"])
      XCTAssertNotNil(flat[1]["boundings.south"])
      XCTAssertNotNil(flat[1]["boundings.east"])
      XCTAssertNotNil(flat[1]["boundings.north"])
      
      // Verify nested location object
      XCTAssertNotNil(flat[1]["location.lat"])
      XCTAssertNotNil(flat[1]["location.lon"])
    }
  }


}
