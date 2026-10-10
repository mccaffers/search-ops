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
final class ResponseTests_Complex_v8: XCTestCase {


  func testLargeObjectBaseline() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.1")
    let objects = Search.getObjects(input: response)
    XCTAssertEqual(objects.data[0].count, 6)
  }
  
  // Handles the testing of very large objects to ensure robustness and correctness in handling extreme cases.
  func testLargeObject() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.6")
    let objects = Search.getObjects(input: response)
    XCTAssertEqual(objects.data[0].count, 11)

  }
  
  func testFieldsSmall() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.1")
    let fields = Fields.getFields(input: response)
    XCTAssertEqual(fields.count, 7)
  }
  
  func testFields() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.7")
    let fields = Fields.getFields(input: response)
    XCTAssertEqual(fields.count, 2)
    XCTAssertTrue(fields.contains(where: {$0.squashedString == "innerException.className"}))
    XCTAssertTrue(fields.contains(where: {$0.squashedString == "innerExceptions.className"}))
  }

  func testFieldsResponse6() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.6")
    let fields = Fields.getFields(input: response)
    // The five "data" fields are always {}, so they hold no value and aren't listed
    XCTAssertEqual(fields.count, 27)
    XCTAssertFalse(fields.contains(where: { $0.squashedString.hasSuffix("data") }))
  }
  
  func testFieldsResponse8() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.8")
    let fields = Fields.getFields(input: response)
    XCTAssertEqual(fields.count, 1)
    XCTAssertTrue(fields.contains(where: {$0.squashedString == "innerExceptions.innerExceptions.className"}))
  }
  
  func testGetArrayValueResponse2() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.2")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let viewableFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    let renderedObjects = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    let nameField = renderedObjects!.headers.first(where: {$0.squashedString == "headers.accept"})

    let output = Results.getValueForKey(fieldParts: nameField!.fieldParts, item:renderedObjects!.results[0])
    
    XCTAssert(output.contains("application/json"))
  }
  
  func testGetArrayValueResponse6() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.6")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let viewableFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    let renderedObjects = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    let nameField = renderedObjects!.headers.first(where: {$0.squashedString == "innerException.className"})

    let output = Results.getValueForKey(fieldParts: nameField!.fieldParts, item:renderedObjects!.results[0])
    
    XCTAssert(output.contains("System.Exception"))
  }
  
  func testGetRenderedObjectsResponse6() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.6")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    let viewableFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    let renderedObjects = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    let innterExceptionField = renderedObjects!.headers.first(where: {$0.squashedString == "innerException.innerException.innerExceptions.className"})
    let innterExceptionOutput = Results.getValueForKey(fieldParts: innterExceptionField!.fieldParts, item:renderedObjects!.results[0])
    XCTAssert(innterExceptionOutput.contains("System.ArgumentOutOfRangeException"))
    
    // innerException.data is always {}, so it holds no value and isn't listed
    XCTAssertNil(renderedObjects!.headers.first(where: {$0.squashedString == "innerException.data"}))
    let innerExceptionDataOutput = Results.getValueForKey(fieldParts: ["innerException", "data"], item:renderedObjects!.results[0])
    XCTAssertEqual(innerExceptionDataOutput, [""])
  }
  
  // Verifies correct retrieval of values from arrays within the parsed fields, addressing complexities in JSON array handling.
  func testGetArrayValueResponse8() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.8")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let viewableFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    let renderedObjects = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    let nameField = renderedObjects!.headers.first(where: {$0.squashedString == "innerExceptions.innerExceptions.className"})
    let output = Results.getValueForKey(fieldParts: nameField!.fieldParts, item:renderedObjects!.results[0])
    
    XCTAssert(output.contains("System.ArgumentOutOfRangeException"))
    
  }
  
  // Verifies correct retrieval of values from arrays within the parsed fields, addressing complexities in JSON array handling.
  func testGetTwoArrayValuesResponse9() async throws {
    let response = try SearchOpsTests().OpenFile(filename: "response.9")
    let objects = Search.getObjects(input: response)
    let fields = Fields.getFields(input: response)
    
    let viewableFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
    viewableFields.fields = Results.SortedFieldsWithDate(input: fields)
    
    let renderedObjects = Results.UpdateResults(searchResults: objects.data, resultsFields: viewableFields)
    
    let nameField = renderedObjects!.headers.first(where: {$0.squashedString == "innerExceptions.innerExceptions.className"})
    let output = Results.getValueForKey(fieldParts: nameField!.fieldParts, item:renderedObjects!.results[0])
    
    XCTAssert(output.contains("System.ArgumentOutOfRangeException"))
    XCTAssert(output.contains("Something Else"))

  }
  
}
