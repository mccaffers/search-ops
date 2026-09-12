// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import RealmSwift

@testable import Search_Ops

final class SearchRenderTests: XCTestCase  {
  
  var searchRender: SearchRender!
  var filterObject: FilterObject!
  var queryObject: QueryObject!
  var squasedFieldsArray: SquashedFieldsArray!
  var relativeRangeFilter: RelativeRangeFilter!
  var sortObject: SortObject!
  var hostDetails: HostDetails!
  var limitObj: LimitObj!
  
  override func setUp() {
    super.setUp()
    
    // Initialize dependencies
    queryObject = QueryObject()
    queryObject.compound = .must  // or .should, as per test case needs
    queryObject.values.append(objectsIn: [
      QueryFilterObject(string: "filter1"),
      QueryFilterObject(string: "filter2")
    ])
    
    squasedFieldsArray = SquashedFieldsArray(squashedString: "exampleField")
    squasedFieldsArray.fieldParts = ["part1", "part2"]
    squasedFieldsArray.type = "text"
    squasedFieldsArray.index = "mainIndex"
    squasedFieldsArray.visible = true
    
    relativeRangeFilter = RelativeRangeFilter(period: .Hours, value: 2.0) // Set to 2 hours for testing
    
    // Initialize SortObject with the squasedFieldsArray
    sortObject = SortObject(order: SortOrderEnum.Ascending, field: squasedFieldsArray)
    
    // Initialize FilterObject with all properties including the SortObject
    filterObject = FilterObject(
      query: queryObject,
      dateField: squasedFieldsArray,
      relativeRange: relativeRangeFilter,
      absoluteRange: nil,  // Adjust with actual parameters
      sort: sortObject  // Use the initialized SortObject
    )
    
    hostDetails = HostDetails()
    hostDetails.host = HostURL()
    hostDetails.host?.url = "example.com"
    hostDetails.host?.port = "8080"
    limitObj = LimitObj(size: 10)
    
    // Initialize the class to be tested
    searchRender = SearchRender()
  }
  
  func testCallWithValidInput() async throws {
    // Arrange
    var result: RenderResult?
    
    // Act
    result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails, index: "testIndex", limitObj: limitObj)
    
    // Assert
    XCTAssertNotNil(result, "Result should not be nil")
    // Add more specific assertions here based on the properties of RenderResult
  }
  
  func testSortObjectProperties() {
    // Test the properties of SortObject
    XCTAssertEqual(sortObject.order, .Ascending)
    XCTAssertEqual(sortObject.field, squasedFieldsArray, "Sort field should match the initialized SquashedFieldsArray")
  }

#if os(macOS)
  func testFieldVisibilityCheck() {
    let field1 = SquashedFieldsArray(squashedString: "fieldA")
    field1.visible = true
    let field2 = SquashedFieldsArray(squashedString: "fieldB")
    field2.visible = false
    let fields = [field1, field2]

    XCTAssertTrue(macosDocumentDetailView.isFieldVisible("fieldA", in: fields))
    XCTAssertFalse(macosDocumentDetailView.isFieldVisible("fieldB", in: fields))
    XCTAssertFalse(macosDocumentDetailView.isFieldVisible("nonexistent", in: fields))
  }

  func testFieldVisibilityFallbackToOnlyVisibleFields() {
    let fields = [SquashedFieldsArray]()
    let visibleField = SquashedFieldsArray(squashedString: "fieldC")
    visibleField.visible = true
    let onlyVisibleFields = [visibleField]

    XCTAssertTrue(macosDocumentDetailView.isFieldVisible("fieldC", in: fields, onlyVisibleFields: onlyVisibleFields))
    XCTAssertFalse(macosDocumentDetailView.isFieldVisible("unknown", in: fields, onlyVisibleFields: onlyVisibleFields))
  }

  func testToggleFieldVisibilityExistingField() {
    let field = SquashedFieldsArray(squashedString: "status")
    field.visible = false
    var fields = [field]
    var onlyVisibleFields = [SquashedFieldsArray]()

    // Toggle on
    let result1 = macosDocumentDetailView.toggleFieldVisibility("status", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(result1)
    XCTAssertTrue(field.visible)
    XCTAssertTrue(onlyVisibleFields.contains(where: { $0.squashedString == "status" && $0.visible }))

    // Toggle off
    let result2 = macosDocumentDetailView.toggleFieldVisibility("status", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertFalse(result2)
    XCTAssertFalse(field.visible)
    XCTAssertFalse(onlyVisibleFields.first(where: { $0.squashedString == "status" })?.visible ?? true)
  }

  func testToggleFieldVisibilityNewField() {
    var fields = [SquashedFieldsArray]()
    var onlyVisibleFields = [SquashedFieldsArray]()

    let result = macosDocumentDetailView.toggleFieldVisibility("user.name", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(result)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(fields[0].squashedString, "user.name")
    XCTAssertEqual(fields[0].fieldParts, ["user", "name"])
    XCTAssertTrue(fields[0].visible)
    XCTAssertEqual(onlyVisibleFields.count, 1)
    XCTAssertEqual(onlyVisibleFields[0].squashedString, "user.name")
    XCTAssertTrue(onlyVisibleFields[0].visible)
    // Verify object reference identity is preserved
    XCTAssertTrue(fields[0] === onlyVisibleFields[0], "fields and onlyVisibleFields should reference the exact same instance")
  }

  func testToggleFieldVisibilityPreExistingOnlyVisibleField() {
    var fields = [SquashedFieldsArray]()
    let unmappedField = SquashedFieldsArray(squashedString: "dynamic.tag", fieldParts: ["dynamic", "tag"])
    unmappedField.type = "keyword"
    unmappedField.visible = false
    var onlyVisibleFields = [unmappedField]

    // Toggle on
    let result = macosDocumentDetailView.toggleFieldVisibility("dynamic.tag", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(result)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(fields[0].squashedString, "dynamic.tag")
    XCTAssertEqual(fields[0].type, "keyword")
    XCTAssertTrue(fields[0].visible)
    XCTAssertTrue(onlyVisibleFields[0].visible)
    XCTAssertTrue(fields[0] === onlyVisibleFields[0], "Existing onlyVisibleField should be reused in fields")
  }

  func testToggleFieldVisibilityMultipleCycles() {
    let field = SquashedFieldsArray(squashedString: "log.level", fieldParts: ["log", "level"])
    var fields = [field]
    var onlyVisibleFields = [field]

    // Cycle 1: On
    _ = macosDocumentDetailView.toggleFieldVisibility("log.level", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(field.visible)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(onlyVisibleFields.count, 1)

    // Cycle 1: Off
    _ = macosDocumentDetailView.toggleFieldVisibility("log.level", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertFalse(field.visible)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(onlyVisibleFields.count, 1)

    // Cycle 2: On
    _ = macosDocumentDetailView.toggleFieldVisibility("log.level", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(field.visible)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(onlyVisibleFields.count, 1)

    // Cycle 2: Off
    _ = macosDocumentDetailView.toggleFieldVisibility("log.level", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertFalse(field.visible)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(onlyVisibleFields.count, 1)
  }

  func testToggleFieldVisibilityDeepNestedKey() {
    var fields = [SquashedFieldsArray]()
    var onlyVisibleFields = [SquashedFieldsArray]()

    let result = macosDocumentDetailView.toggleFieldVisibility("a.b.c.d", fields: &fields, onlyVisibleFields: &onlyVisibleFields)
    XCTAssertTrue(result)
    XCTAssertEqual(fields.count, 1)
    XCTAssertEqual(fields[0].fieldParts, ["a", "b", "c", "d"])
    XCTAssertTrue(fields[0] === onlyVisibleFields[0])
  }
#endif

  override func tearDown() {
    searchRender = nil
    super.tearDown()
  }
}
