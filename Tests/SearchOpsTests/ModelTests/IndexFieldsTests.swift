// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

final class IndexFieldsTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    
    jsonString = """
        {
          "geo": {
            "mappings": {
              "properties": {
                "city": {
                  "type": "text",
                  "fields": {
                    "keyword": {
                      "type": "keyword",
                      "ignore_above": 256
                    }
                  }
                },
                "country": {
                  "type": "text",
                  "fields": {
                    "keyword": {
                      "type": "keyword",
                      "ignore_above": 256
                    }
                  }
                },
                "street": {
                  "type": "text",
                  "fields": {
                    "keyword": {
                      "type": "keyword",
                      "ignore_above": 256
                    }
                  }
                },
                "boundings": {
                  "properties": {
                    "east": {
                      "type": "float"
                    },
                    "north": {
                      "type": "float"
                    },
                    "south": {
                      "type": "float"
                    },
                    "west": {
                      "type": "float"
                    }
                  }
                }
              }
            }
          }
        }

        """
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
    
  var jsonString: String = ""
  
  func testCityFieldMapping() async {
    let map = await IndexMap.indexMappingsResponseToArray(jsonString)
    XCTAssertEqual(map.count, 7, "Should be three properties")
    XCTAssertEqual(map.first(where: {$0.squashedString == "city"})?.fieldParts.count, 1, "City should be of type text")
    XCTAssertEqual(map.filter({$0.squashedString.contains("boundings")}).count, 4, "Should be four bounding entries")
  }

  //   Error handling for missing fields
  func testErrorHandlingForMissingField() async {
    let incompleteJsonString = """
        {
            "geo": {
                "mappings": {
                    "properties": {}
                }
            }
        }
        """
    
    let response = await IndexMap.indexMappingsResponseToArray(incompleteJsonString)
    XCTAssert(response.isEmpty)
    
  }
  
  //   Error handling for unexpected data
  func testErrorHandlingInvalidJSON() async {
    // Invalid json
    let incompleteJsonString = "a{///}}"
    
    let response = await IndexMap.indexMappingsResponseToArray(incompleteJsonString)
    XCTAssert(response.isEmpty)
    
  }
  
    
}
