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
	
	
	
	func testObjectsElasticv5() async throws {
		
		let response = try! SearchOpsTests().OpenFile(filename: "v5_mapping")
		Request.mockedSession = MockURLSession(response: response)
		let output = await IndexMap.indexMappings(serverDetails: HostDetails(), index: "")
		
		let fieldsCount = output.count
		XCTAssertEqual(output.count, 3)

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
