// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import SearchOps

@available(iOS 16.0.0, *)
final class ElasticTests: XCTestCase {
	
	func testValidJSONResponse() async throws {
		
		// {"hello":"world"}
		let jsonResponse = try! SearchOpsTests().OpenFile(filename: "test")
		Request.mockedSession = MockURLSession(response: jsonResponse)
		
		// blank object
		let esDetails = HostDetails()
		esDetails.host = HostURL()
		esDetails.host?.url = "google.com"
		esDetails.host?.port = "443"
		esDetails.host?.scheme = HostScheme.HTTPS
		
		// blank request, validating response handling
		let output = await Search.testHost(serverDetails: esDetails).parsed
		
		// check output
		let json = try! JSON(data: Data(output!.data))
		let hello = json["hello"].string
		
		XCTAssertEqual(hello, "world")
		
	}
	
	func testInvalidInput() async throws {
		
		let jsonResponse = try! SearchOpsTests().OpenFile(filename: "randomText")
		Request.mockedSession = MockURLSession(response: jsonResponse)
		
		// blank object
		let esDetails = HostDetails()
		
		// blank request, validating response handling
		let output = await Search.testHost(serverDetails: esDetails)
		
		XCTAssertEqual(output.parsed?.trimmingCharacters(in: .whitespacesAndNewlines), "abc")
		
	}
	
	func testIndex() async throws {
		
		// {"hello":"world"}
		let jsonResponse = try! SearchOpsTests().OpenFile(filename: "test")
		Request.mockedSession = MockURLSession(response: jsonResponse)
		
		// blank object
		let esDetails = HostDetails()
		
		// blank request, validating response handling
		let output = await Indicies.indexStats(serverDetails: esDetails, index: "")
		
		XCTAssertEqual(output, jsonResponse)
		
	}
	
	func testObjects() async throws {
		
		let response = try! SearchOpsTests().OpenFile(filename: "response.1")
		let output = Search.getObjects(input: response)
		
		let objectCount = output.data.count
		XCTAssertEqual(objectCount, 1)
		
		let hitsCount = Fields.getHits(input: response)
		XCTAssertEqual(hitsCount, 1)
		
	}
	
	func testMappingElasticv8() async throws {
		
		let response = try! SearchOpsTests().OpenFile(filename: "v8_mapping")
		Request.mockedSession = MockURLSession(response: response)
		let output = await IndexMap.indexMappings(serverDetails: HostDetails(), index: "")
		
		let fieldsCount = output.count
		XCTAssertEqual(output.count, 16)
		
	}
	
	func testObjectsElasticv5() async throws {
		
		let response = try! SearchOpsTests().OpenFile(filename: "_mapping")
		Request.mockedSession = MockURLSession(response: response)
		let output = await IndexMap.indexMappings(serverDetails: HostDetails(), index: "")
		
		let fieldsCount = output.count
		XCTAssertEqual(output.count, 3)
		
		
	}
	
	func testObjectsElasticv6() async throws {
		
		let response = try! SearchOpsTests().OpenFile(filename: "v6_mapping")
		Request.mockedSession = MockURLSession(response: response)
		let output = await IndexMap.indexMappings(serverDetails: HostDetails(), index: "")
		
		let fieldsCount = output.count
		XCTAssertEqual(output.count, 17)
		
		
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
	
	func testGetErrorResponse() async throws {
		
		// JSON Response
		let response = try! SearchOpsTests().OpenFile(filename: "error")
		
		// Serialise and extracts the JSON array from the response
		let objects = Search.getObjects(input: response)
		
		//        XCTAssertNil(objects.data
		
		//        let emptyArray : [[String : Any]] = []
		
		XCTAssertEqual(0, objects.data.count)
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
