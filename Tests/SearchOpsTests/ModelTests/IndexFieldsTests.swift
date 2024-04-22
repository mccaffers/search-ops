// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

final class IndexFieldsTests: XCTestCase {
  
  func testHashabilityAndEqualityForFields() {
    let field1 = IndexField(id: UUID(), name: "Field1", type: "String")
    let field2 = IndexField(id: field1.id, name: "Field1", type: "String")
    let field3 = IndexField(id: UUID(), name: "Field2", type: "Number")
    
    XCTAssertEqual(field1, field2, "IndexField instances with the same ID, name, and type should be equal.")
    XCTAssertNotEqual(field1, field3, "IndexField instances with different IDs, names, or types should not be equal.")
    
    var set = Set<IndexField>()
    set.insert(field1)
    set.insert(field2)
    set.insert(field3)
    
    XCTAssertEqual(set.count, 2, "Set should contain two unique items based on their IDs, names, and types.")
  }
  
  func testFunctionalityInCollectionsForFields() {
    var fields = [UUID: IndexField]()
    let field1 = IndexField(id: UUID(), name: "Field1", type: "String")
    let field2 = IndexField(id: UUID(), name: "Field2", type: "Number")
    
    fields[field1.id] = field1
    fields[field2.id] = field2
    
    XCTAssertEqual(fields[field1.id]?.name, "Field1", "The dictionary should retrieve the correct field by ID.")
    XCTAssertEqual(fields.count, 2, "Dictionary should contain exactly two entries.")
  }
  
  func testHashabilityAndEqualityForKeys() {
    let key1 = IndexKey(id: UUID(), name: "Key1")
    let key2 = IndexKey(id: key1.id, name: "Key1")
    let key3 = IndexKey(id: UUID(), name: "Key2")
    
    XCTAssertEqual(key1, key2, "IndexKey instances with the same ID and name should be equal.")
    XCTAssertNotEqual(key1, key3, "IndexKey instances with different IDs or names should not be equal.")
    
    var set = Set<IndexKey>()
    set.insert(key1)
    set.insert(key2)
    set.insert(key3)
    
    XCTAssertEqual(set.count, 2, "Set should contain two unique items based on their IDs and names.")
  }
  
  func testFunctionalityInCollectionsForKeys() {
    var keys = [UUID: IndexKey]()
    let key1 = IndexKey(id: UUID(), name: "Key1")
    let key2 = IndexKey(id: UUID(), name: "Key2")
    
    keys[key1.id] = key1
    keys[key2.id] = key2
    
    XCTAssertEqual(keys[key1.id]?.name, "Key1", "The dictionary should retrieve the correct key by ID.")
    XCTAssertEqual(keys.count, 2, "Dictionary should contain exactly two entries.")
  }
}
