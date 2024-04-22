// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

final class FieldsArrayTests: XCTestCase {

  // Test that two FieldsArray structs with the same name are considered equal.
  func testEquality() {
      let field1 = FieldsArray(name: "FieldA")
      let field2 = FieldsArray(name: "FieldA")
      XCTAssertEqual(field1, field2, "FieldsArray instances with the same name should be equal")
  }

  // Test that two FieldsArray structs with different names are not equal.
  func testInequality() {
      let field1 = FieldsArray(name: "FieldA")
      let field2 = FieldsArray(name: "FieldB")
      XCTAssertNotEqual(field1, field2, "FieldsArray instances with different names should not be equal")
  }

  // Test the hashability by inserting into a set.
  func testHashability() {
      let field1 = FieldsArray(name: "FieldA")
      let field2 = FieldsArray(name: "FieldA")
      let field3 = FieldsArray(name: "FieldB")
      
      var set = Set<FieldsArray>()
      set.insert(field1)
      set.insert(field2)  // This should not increase the size of the set.
      set.insert(field3)  // This should add a second unique item.

      XCTAssertEqual(set.count, 2, "Set should contain exactly two unique items based on name")
  }

  // Test the functionality of nested FieldsArray values.
  func testNestedFieldsArray() {
      let nestedField = FieldsArray(name: "NestedField")
      let field = FieldsArray(name: "Field", values: [nestedField])

      XCTAssertEqual(field.values?.first, nestedField, "Nested FieldsArray should be correctly assigned and retrievable")
  }

}
