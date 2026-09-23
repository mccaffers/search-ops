// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import RealmSwift
import OrderedCollections

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

  func testCallWithQueryShardException() async throws {
    let mockResponse = """
    {
      "error": {
        "root_cause": [
          {
            "type": "query_shard_exception",
            "reason": "Failed to parse query [test]"
          }
        ]
      },
      "status": 400
    }
    """
    Request.mockedSession = MockURLSession(response: mockResponse)
    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails, index: "testIndex", limitObj: limitObj)
    
    XCTAssertNotNil(result.error)
    XCTAssertEqual(result.error?.title, "query_shard_exception")
    XCTAssertEqual(result.error?.message, "Failed to parse query [test]")
  }

  func testCallWithParsingException() async throws {
    let mockResponse = """
    {
      "error": {
        "root_cause": [
          {
            "type": "parsing_exception",
            "reason": "Unknown query type"
          }
        ]
      },
      "status": 400
    }
    """
    Request.mockedSession = MockURLSession(response: mockResponse)
    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails, index: "testIndex", limitObj: limitObj)
    
    XCTAssertNotNil(result.error)
    XCTAssertEqual(result.error?.title, "parsing_exception")
    XCTAssertEqual(result.error?.message, "Unknown query type")
  }

  func testCallWithUnknownExceptionFallback() async throws {
    let mockResponse = """
    {
      "error": {
        "reason": "Something broke"
      },
      "status": 500
    }
    """
    Request.mockedSession = MockURLSession(response: mockResponse)
    let result = await SearchRender.call(pageInput: 1, filterObject: filterObject, host: hostDetails, index: "testIndex", limitObj: limitObj)
    
    XCTAssertNotNil(result.error)
    XCTAssertEqual(result.error?.title, "Query Error")
    XCTAssertEqual(result.error?.message, "Something broke")
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

  func testSyncVisibilityPreservesMappedFields() {
    let source1 = SquashedFieldsArray(squashedString: "fieldA")
    source1.visible = true
    let source2 = SquashedFieldsArray(squashedString: "fieldB")
    source2.visible = false
    let sourceFields = [source1, source2]
    let sourceOnlyVisible = [SquashedFieldsArray]()

    let target1 = SquashedFieldsArray(squashedString: "fieldA")
    target1.visible = false
    let target2 = SquashedFieldsArray(squashedString: "fieldB")
    target2.visible = false
    let target3 = SquashedFieldsArray(squashedString: "fieldC")
    target3.visible = false
    var targetFields = [target1, target2, target3]
    var targetOnlyVisible = [SquashedFieldsArray]()

    macosSearchMainView.syncVisibility(
      sourceFields: sourceFields,
      sourceOnlyVisible: sourceOnlyVisible,
      targetFields: &targetFields,
      targetOnlyVisible: &targetOnlyVisible
    )

    XCTAssertTrue(target1.visible, "fieldA was visible in source and should be marked visible in target")
    XCTAssertFalse(target2.visible, "fieldB was false in source and should remain false")
    XCTAssertFalse(target3.visible, "fieldC was not in source and should remain false")
  }

  func testSyncVisibilityPreservesOnlyVisibleFields() {
    let source1 = SquashedFieldsArray(squashedString: "fieldA")
    source1.visible = true
    let sourceFields = [source1]

    let sourceVis1 = SquashedFieldsArray(squashedString: "fieldB")
    sourceVis1.visible = true
    let sourceVis2 = SquashedFieldsArray(squashedString: "fieldC")
    sourceVis2.visible = false
    let sourceOnlyVisible = [sourceVis1, sourceVis2]

    var targetFields = [SquashedFieldsArray]()

    let targetVis1 = SquashedFieldsArray(squashedString: "fieldA")
    targetVis1.visible = false
    let targetVis2 = SquashedFieldsArray(squashedString: "fieldB")
    targetVis2.visible = false
    let targetVis3 = SquashedFieldsArray(squashedString: "fieldC")
    targetVis3.visible = false
    let targetVis4 = SquashedFieldsArray(squashedString: "fieldD")
    targetVis4.visible = false
    var targetOnlyVisible = [targetVis1, targetVis2, targetVis3, targetVis4]

    macosSearchMainView.syncVisibility(
      sourceFields: sourceFields,
      sourceOnlyVisible: sourceOnlyVisible,
      targetFields: &targetFields,
      targetOnlyVisible: &targetOnlyVisible
    )

    XCTAssertTrue(targetVis1.visible, "fieldA was visible in sourceFields, should be visible in targetOnlyVisible")
    XCTAssertTrue(targetVis2.visible, "fieldB was visible in sourceOnlyVisible, should be visible in targetOnlyVisible")
    XCTAssertFalse(targetVis3.visible, "fieldC was false in sourceOnlyVisible, should remain false")
    XCTAssertFalse(targetVis4.visible, "fieldD was not in visibleKeys, should remain false")
  }

  func testSyncVisibilityRetainsUnmappedDynamicFields() {
    let mappedField = SquashedFieldsArray(squashedString: "mapped.field")
    mappedField.visible = true
    let dynamicField = SquashedFieldsArray(squashedString: "dynamic.field", fieldParts: ["dynamic", "field"])
    dynamicField.type = "keyword"
    dynamicField.visible = true
    let hiddenDynamicField = SquashedFieldsArray(squashedString: "hidden.field", fieldParts: ["hidden", "field"])
    hiddenDynamicField.visible = false

    let sourceFields = [mappedField, dynamicField, hiddenDynamicField]
    let sourceOnlyVisible = [SquashedFieldsArray]()

    let targetMapped = SquashedFieldsArray(squashedString: "mapped.field")
    targetMapped.visible = false
    let targetOther = SquashedFieldsArray(squashedString: "other.mapped")
    targetOther.visible = false
    var targetFields = [targetMapped, targetOther]
    var targetOnlyVisible = [SquashedFieldsArray]()

    macosSearchMainView.syncVisibility(
      sourceFields: sourceFields,
      sourceOnlyVisible: sourceOnlyVisible,
      targetFields: &targetFields,
      targetOnlyVisible: &targetOnlyVisible
    )

    XCTAssertEqual(targetFields.count, 3, "targetFields should retain the unmapped dynamic field that was visible")
    XCTAssertTrue(targetMapped.visible, "mapped.field should be marked visible")
    XCTAssertFalse(targetOther.visible, "other.mapped should remain false")
    XCTAssertTrue(targetFields.contains(where: { $0.squashedString == "dynamic.field" && $0.visible }), "dynamic.field should be preserved with visible=true")
    XCTAssertFalse(targetFields.contains(where: { $0.squashedString == "hidden.field" }), "hidden unmapped fields should not be added")
  }

  func testSyncVisibilityEmptySourcesDoesNotModifyTargets() {
    let target1 = SquashedFieldsArray(squashedString: "fieldA")
    target1.visible = false
    var targetFields = [target1]

    let targetVis1 = SquashedFieldsArray(squashedString: "fieldB")
    targetVis1.visible = false
    var targetOnlyVisible = [targetVis1]

    macosSearchMainView.syncVisibility(
      sourceFields: [],
      sourceOnlyVisible: [],
      targetFields: &targetFields,
      targetOnlyVisible: &targetOnlyVisible
    )

    XCTAssertEqual(targetFields.count, 1)
    XCTAssertFalse(target1.visible)
    XCTAssertEqual(targetOnlyVisible.count, 1)
    XCTAssertFalse(targetVis1.visible)
  }

  func testSyncVisibilityPreservesMultipleFieldsWithoutDuplicates() {
    let dyn1 = SquashedFieldsArray(squashedString: "dyn1", fieldParts: ["dyn1"])
    dyn1.visible = true
    let dyn2 = SquashedFieldsArray(squashedString: "dyn1", fieldParts: ["dyn1"])
    dyn2.visible = true
    let sourceFields = [dyn1, dyn2]
    let sourceOnlyVisible = [SquashedFieldsArray]()

    var targetFields = [SquashedFieldsArray]()
    var targetOnlyVisible = [SquashedFieldsArray]()

    macosSearchMainView.syncVisibility(
      sourceFields: sourceFields,
      sourceOnlyVisible: sourceOnlyVisible,
      targetFields: &targetFields,
      targetOnlyVisible: &targetOnlyVisible
    )

    XCTAssertEqual(targetFields.count, 1, "Duplicate visible source fields should not create duplicates in targetFields")
    XCTAssertEqual(targetFields[0].squashedString, "dyn1")
    XCTAssertTrue(targetFields[0].visible)
  }

  func testKeyedCacheLogic() {
    let hostId = UUID()
    let otherHostId = UUID()
    let index = "test-index"
    let otherIndex = "other-index"

    let currentKey = macosSearchMainView.computeCacheKey(hostId: hostId, index: index)
    XCTAssertEqual(currentKey, "\(hostId.uuidString)|\(index)")

    let field = SquashedFieldsArray(squashedString: "fieldA")
    let fields = [field]

    // Cache hit: same host, same index, non-empty fields
    let hit = macosSearchMainView.isCacheValid(fields: fields, fieldsCacheKey: currentKey, currentKey: currentKey)
    XCTAssertTrue(hit, "Cache should be valid when host, index, and non-empty fields match")

    // Cache miss: empty fields
    let emptyMiss = macosSearchMainView.isCacheValid(fields: [], fieldsCacheKey: currentKey, currentKey: currentKey)
    XCTAssertFalse(emptyMiss, "Cache should be invalid when fields are empty")

    // Cache miss: different index
    let otherIndexKey = macosSearchMainView.computeCacheKey(hostId: hostId, index: otherIndex)
    let indexMiss = macosSearchMainView.isCacheValid(fields: fields, fieldsCacheKey: currentKey, currentKey: otherIndexKey)
    XCTAssertFalse(indexMiss, "Cache should be invalid when index changes")

    // Cache miss: different host
    let otherHostKey = macosSearchMainView.computeCacheKey(hostId: otherHostId, index: index)
    let hostMiss = macosSearchMainView.isCacheValid(fields: fields, fieldsCacheKey: currentKey, currentKey: otherHostKey)
    XCTAssertFalse(hostMiss, "Cache should be invalid when host changes")
  }

  func testSyncVisibilityOnReusePathDoesNotResurrectHiddenFields() {
    let fieldA = SquashedFieldsArray(squashedString: "fieldA")
    fieldA.visible = false
    let fieldB = SquashedFieldsArray(squashedString: "fieldB")
    fieldB.visible = true
    let fields = [fieldA, fieldB]

    let visA = SquashedFieldsArray(squashedString: "fieldA")
    visA.visible = false
    let visB = SquashedFieldsArray(squashedString: "fieldB")
    visB.visible = false
    var onlyVisibleFields = [visA, visB]

    var unused = [SquashedFieldsArray]()
    macosSearchMainView.syncVisibility(
      sourceFields: fields,
      sourceOnlyVisible: [],
      targetFields: &unused,
      targetOnlyVisible: &onlyVisibleFields
    )

    XCTAssertFalse(fieldA.visible, "Hidden field in fields must remain false")
    XCTAssertTrue(fieldB.visible, "Visible field in fields must remain true")
    XCTAssertFalse(visA.visible, "Hidden field must not be resurrected in onlyVisibleFields")
    XCTAssertTrue(visB.visible, "Visible field must be marked visible in onlyVisibleFields")
  }

  func testSetFieldVisibilitySyncsBothArrays() {
    let item = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    item.visible = false
    let itemInFields = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    itemInFields.visible = false
    let itemInOnlyVis = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    itemInOnlyVis.visible = false

    let fields = [itemInFields]
    let onlyVisible = [itemInOnlyVis]

    // Toggle on
    let changed = macosSearchFieldSheetView.setFieldVisibility(
      item: item,
      visible: true,
      fields: fields,
      onlyVisibleFields: onlyVisible
    )
    XCTAssertTrue(changed)
    XCTAssertTrue(item.visible)
    XCTAssertTrue(itemInFields.visible)
    XCTAssertTrue(itemInOnlyVis.visible)

    // Redundant toggle on should return false
    let redundant = macosSearchFieldSheetView.setFieldVisibility(
      item: item,
      visible: true,
      fields: fields,
      onlyVisibleFields: onlyVisible
    )
    XCTAssertFalse(redundant)

    // Toggle off
    let changedOff = macosSearchFieldSheetView.setFieldVisibility(
      item: item,
      visible: false,
      fields: fields,
      onlyVisibleFields: onlyVisible
    )
    XCTAssertTrue(changedOff)
    XCTAssertFalse(item.visible)
    XCTAssertFalse(itemInFields.visible)
    XCTAssertFalse(itemInOnlyVis.visible)
  }

  func testBodyFilteredFieldsExcludesDateField() {
    let dateField = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    dateField.visible = true
    let bodyField1 = SquashedFieldsArray(squashedString: "threadCount", fieldParts: ["threadCount"])
    bodyField1.visible = true
    let bodyField2 = SquashedFieldsArray(squashedString: "message", fieldParts: ["message"])
    bodyField2.visible = false

    let allFields = [dateField, bodyField1, bodyField2]

    let bodyFiltered = macosSearchMainView.computeBodyFilteredFields(
      fields: allFields,
      activeDateField: dateField
    )

    XCTAssertEqual(bodyFiltered.count, 1)
    XCTAssertEqual(bodyFiltered[0].squashedString, "threadCount")
    XCTAssertFalse(bodyFiltered.contains(where: { $0.squashedString == "timestamp" }))
    XCTAssertFalse(bodyFiltered.contains(where: { $0.squashedString == "message" }))
  }

  func testShowDateHeaderReflectsDateFieldVisibility() {
    let dateField = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    dateField.visible = true
    let otherField = SquashedFieldsArray(squashedString: "message", fieldParts: ["message"])
    otherField.visible = true

    // Active and visible -> true
    XCTAssertTrue(macosSearchMainView.shouldShowDateHeader(fields: [dateField, otherField], activeDateField: dateField))

    // Active but hidden -> false
    dateField.visible = false
    XCTAssertFalse(macosSearchMainView.shouldShowDateHeader(fields: [dateField, otherField], activeDateField: dateField))

    // Active date field is nil -> false
    XCTAssertFalse(macosSearchMainView.shouldShowDateHeader(fields: [dateField, otherField], activeDateField: nil))

    // Active date field not in fields -> false
    let missingDateField = SquashedFieldsArray(squashedString: "missing", fieldParts: ["missing"])
    missingDateField.visible = true
    XCTAssertFalse(macosSearchMainView.shouldShowDateHeader(fields: [dateField, otherField], activeDateField: missingDateField))
  }

  func testUnconditionalDateRemovalFromItem() {
    var item = OrderedDictionary<String, Any>()
    item["timestamp"] = ["2026-09-20T12:00:00Z"]
    item["message"] = ["Server started"]

    var itemWithoutDate = item
    itemWithoutDate.removeValue(forKey: "timestamp")

    // Unfiltered path: filteredFields is empty
    let unfilteredResult = ElasticDocumentBuilder.exportFlatValues(input: itemWithoutDate, filteredFields: [])
    let unfilteredValues = unfilteredResult.map { $0.value }
    XCTAssertTrue(unfilteredValues.contains("message"))
    XCTAssertTrue(unfilteredValues.contains("Server started"))
    XCTAssertFalse(unfilteredValues.contains("timestamp"))
    XCTAssertFalse(unfilteredValues.contains("2026-09-20T12:00:00Z"))

    // Filtered path: filteredFields has message
    let messageField = SquashedFieldsArray(squashedString: "message", fieldParts: ["message"])
    messageField.visible = true
    let filteredResult = ElasticDocumentBuilder.exportFlatValues(input: itemWithoutDate, filteredFields: [messageField])
    let filteredValues = filteredResult.map { $0.value }
    XCTAssertTrue(filteredValues.contains("message"))
    XCTAssertTrue(filteredValues.contains("Server started"))
    XCTAssertFalse(filteredValues.contains("timestamp"))
  }

  func testRowVisibilityWithBodyFiltersExcludesMissingFields() {
    // 1. Body filtered, missing body fields -> should NOT show row (no ghost card)
    XCTAssertFalse(macOSDocumentSearchView.shouldDisplayRow(
      hasBodyContent: false,
      showDateHeader: true,
      hasDateValue: true,
      isBodyFiltered: true
    ))

    // 2. Body filtered, has body fields -> should show row
    XCTAssertTrue(macOSDocumentSearchView.shouldDisplayRow(
      hasBodyContent: true,
      showDateHeader: true,
      hasDateValue: true,
      isBodyFiltered: true
    ))

    // 3. Body filtered, has body fields, date hidden -> should show row
    XCTAssertTrue(macOSDocumentSearchView.shouldDisplayRow(
      hasBodyContent: true,
      showDateHeader: false,
      hasDateValue: false,
      isBodyFiltered: true
    ))

    // 4. Body unfiltered, has body fields -> should show row
    XCTAssertTrue(macOSDocumentSearchView.shouldDisplayRow(
      hasBodyContent: true,
      showDateHeader: true,
      hasDateValue: true,
      isBodyFiltered: false
    ))

    // 5. Body unfiltered, has NO body fields but has date header & value -> should show row
    XCTAssertTrue(macOSDocumentSearchView.shouldDisplayRow(
      hasBodyContent: false,
      showDateHeader: true,
      hasDateValue: true,
      isBodyFiltered: false
    ))

    // 6. Body unfiltered, has NO body fields and date header hidden -> should NOT show row
    XCTAssertFalse(macOSDocumentSearchView.shouldDisplayRow(
      hasBodyContent: false,
      showDateHeader: false,
      hasDateValue: true,
      isBodyFiltered: false
    ))
  }

  func testDateFieldPickerSwitchSyncsRenderedObject() {
    let oldDateField = SquashedFieldsArray(squashedString: "timestamp", fieldParts: ["timestamp"])
    oldDateField.visible = true
    let newDateField = SquashedFieldsArray(squashedString: "@timestamp", fieldParts: ["@timestamp"])
    newDateField.visible = false

    var fields = [oldDateField, newDateField]
    var onlyVisible = [oldDateField, newDateField]
    var currentActive: String? = "timestamp"
    var rendered: RenderObject? = RenderObject(headers: [], results: [], flat: [], dateField: oldDateField)

    // Switch to newDateField
    let switched = macosSearchMainView.switchDateField(
      newDateField: newDateField,
      currentActiveDateField: &currentActive,
      fields: &fields,
      onlyVisibleFields: &onlyVisible,
      renderedObjects: &rendered
    )

    XCTAssertTrue(switched)
    XCTAssertEqual(currentActive, "@timestamp")
    XCTAssertFalse(oldDateField.visible)
    XCTAssertTrue(newDateField.visible)
    XCTAssertEqual(rendered?.dateField?.squashedString, "@timestamp")

    // Switching to same field returns false (no-op)
    let noOp = macosSearchMainView.switchDateField(
      newDateField: newDateField,
      currentActiveDateField: &currentActive,
      fields: &fields,
      onlyVisibleFields: &onlyVisible,
      renderedObjects: &rendered
    )
    XCTAssertFalse(noOp)

    // Switch to nil
    let switchedToNil = macosSearchMainView.switchDateField(
      newDateField: nil,
      currentActiveDateField: &currentActive,
      fields: &fields,
      onlyVisibleFields: &onlyVisible,
      renderedObjects: &rendered
    )
    XCTAssertTrue(switchedToNil)
    XCTAssertNil(currentActive)
    XCTAssertFalse(newDateField.visible)
    XCTAssertNil(rendered?.dateField)
  }

  func testSwitchDateFieldSetsVisibleOnPassedInstance() {
    let externalDateField = SquashedFieldsArray(squashedString: "created_at", fieldParts: ["created_at"])
    externalDateField.visible = false

    var fields = [externalDateField]
    var onlyVisible = [externalDateField]
    var currentActive: String? = nil
    var rendered: RenderObject? = nil

    let switched = macosSearchMainView.switchDateField(
      newDateField: externalDateField,
      currentActiveDateField: &currentActive,
      fields: &fields,
      onlyVisibleFields: &onlyVisible,
      renderedObjects: &rendered
    )

    XCTAssertTrue(switched)
    XCTAssertTrue(externalDateField.visible, "The passed newDateField instance must have visible set to true")
    XCTAssertEqual(currentActive, "created_at")
  }

  func testSwitchDateFieldNilToNilIsNoOp() {
    var fields = [SquashedFieldsArray]()
    var onlyVisible = [SquashedFieldsArray]()
    var currentActive: String? = nil
    var rendered: RenderObject? = nil

    let switched = macosSearchMainView.switchDateField(
      newDateField: nil,
      currentActiveDateField: &currentActive,
      fields: &fields,
      onlyVisibleFields: &onlyVisible,
      renderedObjects: &rendered
    )

    XCTAssertFalse(switched, "Switching nil to nil must be a no-op returning false")
    XCTAssertNil(currentActive)
  }

  func testMultipleDateFieldsTreatsSecondaryDateAsBodyField() {
    let primaryDateField = SquashedFieldsArray(squashedString: "@timestamp", fieldParts: ["@timestamp"])
    primaryDateField.type = "date"
    primaryDateField.visible = true

    let secondaryDateField = SquashedFieldsArray(squashedString: "event_time", fieldParts: ["event_time"])
    secondaryDateField.type = "date"
    secondaryDateField.visible = true

    let regularField = SquashedFieldsArray(squashedString: "message", fieldParts: ["message"])
    regularField.type = "text"
    regularField.visible = false

    let allFields = [primaryDateField, secondaryDateField, regularField]

    // Verify date header reflects only the primary active date field
    XCTAssertTrue(macosSearchMainView.shouldShowDateHeader(fields: allFields, activeDateField: primaryDateField))

    // Verify body filtered fields includes the secondary date field, but strips the primary date field
    let bodyFiltered = macosSearchMainView.computeBodyFilteredFields(fields: allFields, activeDateField: primaryDateField)
    XCTAssertEqual(bodyFiltered.count, 1)
    XCTAssertEqual(bodyFiltered[0].squashedString, "event_time")
    XCTAssertFalse(bodyFiltered.contains(where: { $0.squashedString == "@timestamp" }))
  }
#endif

  override func tearDown() {
    Request.mockedSession = nil
    searchRender = nil
    super.tearDown()
  }
}
