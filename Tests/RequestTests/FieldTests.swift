// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import OrderedCollections

@testable import Search_Ops

// Indicates that this test class is only to be used with iOS 16.0.0 and above.
@available(iOS 16.0.0, *)
final class FieldTests: XCTestCase {

  /// Flattens documents written as a JSON array, so values arrive as they do from a server.
  func flatten(_ json: String) throws -> FlatPage {
    let data = try XCTUnwrap(json.data(using: .utf8))
    let documents = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [[String: Any]])
    return DocumentFlattener.flattenPage(documents)
  }

  func values(_ page: FlatPage, row: Int = 0) -> [String: [String]] {
    page.rows[row].reduce(into: [:]) { $0[$1.key] = $1.value as? [String] }
  }

  func keys(_ page: FlatPage) -> [String] {
    page.fields.map(\.key)
  }

  // MARK: - Values

  func testBooleansReadTrueAndFalse() throws {
    let page = try flatten(#"[{"ok":true,"user":{"flag":false},"flags":[true,false],"mixed":[true,1,"x"]}]"#)
    XCTAssertEqual(values(page), ["ok": ["true"], "user.flag": ["false"], "flags": ["true", "false"], "mixed": ["true", "1", "x"]])
  }

  func testNumbersReadAsBefore() throws {
    let json = #"[{"i":3,"w":3.0,"f":3.14,"neg":-0.5,"big":12345678901,"huge":1e20,"tiny":2.5e-7,"list":[1,2.5,3.0]}]"#
    let page = try flatten(json)
    XCTAssertEqual(values(page), ["i": ["3"], "w": ["3"], "f": ["3.14"], "neg": ["-0.5"], "big": ["12345678901"],
                                  "huge": ["1e+20"], "tiny": ["2.5e-07"], "list": ["1", "2.5", "3"]])

    // The same text as the field lookup
    let document = try XCTUnwrap(JsonTools.serialiseJson(String(json.dropFirst().dropLast())))
    let ordered = OrderedDictionary(uniqueKeys: document.keys, values: document.values)
    for field in page.fields {
      XCTAssertEqual(values(page)[field.key], Results.getValueForKey(fieldParts: field.parts, item: ordered), field.key)
    }
  }

  func testStringsAreKeptAsTheyAre() throws {
    let page = try flatten(#"[{"empty":"","space":"  ","text":"a, b","quoted":"true"}]"#)
    XCTAssertEqual(values(page), ["empty": [""], "space": ["  "], "text": ["a, b"], "quoted": ["true"]])
  }

  func testNullHasNoValue() throws {
    let page = try flatten(#"""
    [{"n":null,"a":[1,null,2],"allnull":[null],"o":{"n":null,"v":1}},
     {"n":5,"a":null}]
    """#)
    XCTAssertEqual(values(page, row: 0), ["a": ["1", "2"], "o.v": ["1"]])
    XCTAssertEqual(values(page, row: 1), ["n": ["5"]])
    XCTAssertEqual(keys(page), ["a", "n", "o.v"], "Fields only ever null aren't listed")
  }

  func testEmptyObjectsAndArraysHaveNoValue() throws {
    let page = try flatten(#"[{"e":{},"l":[],"o":{"e":{},"l":[[]],"v":"x"}}]"#)
    XCTAssertEqual(values(page), ["o.v": ["x"]])
    XCTAssertEqual(keys(page), ["o.v"])
  }

  func testArraysOfObjectsMergeEveryElement() throws {
    let page = try flatten(#"""
    [{"items":[{"a":"x1","onlyFirst":"y1"},{"a":"x2"}]},
     {"items":[{"a":"x3"}]}]
    """#)
    XCTAssertEqual(values(page, row: 0), ["items.a": ["x1", "x2"], "items.onlyFirst": ["y1"]])
    XCTAssertEqual(values(page, row: 1), ["items.a": ["x3"]])
    XCTAssertEqual(page.fields, [FlatField(key: "items.a", parts: ["items", "a"]),
                                 FlatField(key: "items.onlyFirst", parts: ["items", "onlyFirst"])])
  }

  func testArraysOfArraysAreFlattened() throws {
    let page = try flatten(#"[{"matrix":[[1,2],[3,4]],"objs":[[{"k":1}],[{"k":2}]]}]"#)
    XCTAssertEqual(values(page), ["matrix": ["1", "2", "3", "4"], "objs.k": ["1", "2"]])
  }

  func testFieldCanBeValueInOneDocumentAndObjectInAnother() throws {
    let page = try flatten(#"[{"a":{"b":"leaf"}},{"a":{"b":{"c":"object"}}}]"#)
    XCTAssertEqual(values(page, row: 0), ["a.b": ["leaf"]])
    XCTAssertEqual(values(page, row: 1), ["a.b.c": ["object"]])
    XCTAssertEqual(keys(page), ["a.b", "a.b.c"])
  }

  // MARK: - Dotted keys

  func testDottedKeyMergesWithNestedKey() throws {
    let page = try flatten(#"[{"host.name":"literal","host":{"name":"nested","ip":"1.2.3.4"}}]"#)
    XCTAssertEqual(values(page)["host.name"]?.sorted(), ["literal", "nested"])
    XCTAssertEqual(page.fields, [FlatField(key: "host.ip", parts: ["host", "ip"]),
                                 FlatField(key: "host.name", parts: ["host", "name"])])
  }

  func testDottedKeyKeepsItsOwnPartsWhenAlone() throws {
    let page = try flatten(#"[{"host.name":"only-literal"}]"#)
    XCTAssertEqual(page.fields, [FlatField(key: "host.name", parts: ["host.name"])])
  }

  func testNestedPartsWinAcrossDocuments() throws {
    let literalFirst = try flatten(#"[{"host.name":"a"},{"host":{"name":"b"}}]"#)
    let nestedFirst = try flatten(#"[{"host":{"name":"b"}},{"host.name":"a"}]"#)
    XCTAssertEqual(literalFirst.fields, [FlatField(key: "host.name", parts: ["host", "name"])])
    XCTAssertEqual(nestedFirst.fields, literalFirst.fields)
  }

  func testEqualDepthPartsPickedAlphabetically() throws {
    let page = try flatten(#"[{"a.b":{"c":1},"a":{"b.c":2}}]"#)
    XCTAssertEqual(values(page)["a.b.c"]?.sorted(), ["1", "2"])
    XCTAssertEqual(page.fields, [FlatField(key: "a.b.c", parts: ["a", "b.c"])])

    // Whichever document comes first
    let firstWay = try flatten(#"[{"a.b":{"c":1}},{"a":{"b.c":2}}]"#)
    let otherWay = try flatten(#"[{"a":{"b.c":2}},{"a.b":{"c":1}}]"#)
    XCTAssertEqual(firstWay.fields, [FlatField(key: "a.b.c", parts: ["a", "b.c"])])
    XCTAssertEqual(otherWay.fields, firstWay.fields)
  }

  // MARK: - Rows and fields

  func testRowsAndFieldsAreSortedByName() throws {
    let page = try flatten(#"[{"z":1,"b":{"y":1,"a":2},"a":"x"},{},{"m":true}]"#)
    XCTAssertEqual(page.rows.count, 3)
    XCTAssertEqual(page.rows[0].keys.elements, ["a", "b.a", "b.y", "z"])
    XCTAssertTrue(page.rows[1].isEmpty)
    XCTAssertEqual(keys(page), ["a", "b.a", "b.y", "m", "z"])
    XCTAssertEqual(keys(page), keys(page).sorted())
  }

  func testUnicodeKeys() throws {
    let page = try flatten(#"[{"ü":"ñ","日本":{"語":"値"},"emoji🙂":1}]"#)
    XCTAssertEqual(values(page), ["ü": ["ñ"], "日本.語": ["値"], "emoji🙂": ["1"]])
    XCTAssertEqual(page.fields.first { $0.key == "日本.語" }?.parts, ["日本", "語"])
  }

  func testDeeplyNestedDocument() throws {
    let depth = 60
    let json = String(repeating: #"{"l":"#, count: depth) + #""bottom""# + String(repeating: "}", count: depth)
    let page = try flatten("[" + json + "]")
    let key = Array(repeating: "l", count: depth).joined(separator: ".")
    XCTAssertEqual(values(page), [key: ["bottom"]])
    XCTAssertEqual(page.fields.first?.parts.count, depth)
  }

  func testNoDocuments() {
    let page = DocumentFlattener.flattenPage([])
    XCTAssertTrue(page.rows.isEmpty)
    XCTAssertTrue(page.fields.isEmpty)
  }

  // MARK: - Response helpers

  func testGetFieldsMatchesSearchFields() throws {
    for name in ["response.3", "response.5", "response.6", "v5_search"] {
      let response = try SearchOpsTests().OpenFile(filename: name)
      let fromSearch = Search.getObjects(input: response).fields
      let fromFields = Fields.getFields(input: response)
      XCTAssertEqual(fromFields.map(\.squashedString), fromSearch.map(\.squashedString), name)
      XCTAssertEqual(fromFields.map(\.fieldParts), fromSearch.map(\.fieldParts), name)
    }
    XCTAssertTrue(Fields.getFields(input: "not json").isEmpty)
  }

  func testSearchRowsLineUpWithDocuments() throws {
    let response = #"""
    {"hits":{"total":{"value":3},"hits":[
      {"_id":"1","_source":{"a":1}},{"_id":"no-source"},{"_id":"2","_source":{"b":true}}]}}
    """#
    let result = Search.getObjects(input: response)
    XCTAssertEqual(result.data.count, 2)
    XCTAssertEqual(result.rows.map { $0.keys.elements }, [["a"], ["b"]])
    XCTAssertEqual(result.rows.first?["a"] as? [String], ["1"])
    XCTAssertEqual(result.rows.last?["b"] as? [String], ["true"])
  }

  func testSearchHitCountNotesWhenTheServerStoppedCounting() {
    let capped = Search.getObjects(input: #"{"hits":{"total":{"value":10000,"relation":"gte"},"hits":[{"_source":{"a":1}}]}}"#)
    XCTAssertEqual(capped.hitCount, 10000)
    XCTAssertTrue(capped.hitCountIsLowerBound)

    let exact = Search.getObjects(input: #"{"hits":{"total":{"value":60,"relation":"eq"},"hits":[{"_source":{"a":1}}]}}"#)
    XCTAssertEqual(exact.hitCount, 60)
    XCTAssertFalse(exact.hitCountIsLowerBound)

    let legacy = Search.getObjects(input: #"{"hits":{"total":42,"hits":[{"_source":{"a":1}}]}}"#)
    XCTAssertEqual(legacy.hitCount, 42)
    XCTAssertFalse(legacy.hitCountIsLowerBound)
  }

  func testHitCountLabel() {
    XCTAssertEqual(SearchResult.hitCountLabel(0), "0 hits")
    XCTAssertEqual(SearchResult.hitCountLabel(1), "1 hit")
    XCTAssertEqual(SearchResult.hitCountLabel(60), "60 hits")
    XCTAssertEqual(SearchResult.hitCountLabel(10000, isLowerBound: true), "\(10000.formatted())+ hits")
  }

  func testFlatResultsUseRowsAlreadyBuilt() {
    let rows: [OrderedDictionary<String, Any>] = [["given": ["row"]]]
    let result = Results.UpdateResultsWithFlatArray(searchResults: [["a": 1]], resultsFields: RenderedFields(fields: []), rows: rows)
    XCTAssertEqual(result?.flat?.first?["given"] as? [String], ["row"])
    XCTAssertNil(result?.flat?.first?["a"])

    let built = Results.UpdateResultsWithFlatArray(searchResults: [["a": 1]], resultsFields: RenderedFields(fields: []))
    XCTAssertEqual(built?.flat?.first?["a"] as? [String], ["1"])
  }

  // MARK: - Field lookup (iOS)

  func item(_ json: String) throws -> OrderedDictionary<String, Any> {
    let document = try XCTUnwrap(JsonTools.serialiseJson(json))
    return OrderedDictionary(uniqueKeys: document.keys, values: document.values)
  }

  func testLookupReadsBooleansAsTrueAndFalse() throws {
    let item = try item(#"{"ok":true,"flags":[true,false],"user":{"flag":false,"flags":[false,true]},"n":1}"#)
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["ok"], item: item), ["true"])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["user", "flag"], item: item), ["false"])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["flags"], item: item), ["true", "false"])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["user", "flags"], item: item), ["false", "true"])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["n"], item: item), ["1"], "Numbers aren't booleans")
  }

  func testLookupReadsArraysInsideObjects() throws {
    let item = try item(#"{"host":{"ip":["10.0.0.1","fe80::1"],"ports":[80,443],"mixed":[1,"a",null,true,2.5]}}"#)
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["host", "ip"], item: item), ["10.0.0.1", "fe80::1"])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["host", "ports"], item: item), ["80", "443"])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["host", "mixed"], item: item), ["1", "a", "true", "2.5"])
  }

  func testLookupReadsArraysOfObjectsAndArrays() throws {
    let item = try item(#"{"items":[{"a":"x1"},{"b":"no a"},{"a":"x2"}],"matrix":[[1,2],[3]],"objs":[[{"k":1}],[{"k":2}]]}"#)
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["items", "a"], item: item), ["x1", "x2"],
                   "Elements without the field add nothing, rather than a blank")
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["matrix"], item: item), ["1", "2", "3"])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["objs", "k"], item: item), ["1", "2"])
  }

  func testLookupWithoutValue() throws {
    let item = try item(#"{"a":{"b":{"c":"object"}},"n":null,"e":{},"l":[],"p":"leaf"}"#)
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["a", "b"], item: item), [""], "A path ending at an object")
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["n"], item: item), [""])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["e"], item: item), [""])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["l"], item: item), [""])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["missing"], item: item), [""])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["p", "deeper"], item: item), [""], "A value part way along the path")
    XCTAssertEqual(Results.getValueForKey(fieldParts: [], item: item), [""])
  }

  func testLookupMatchesDottedAndNestedKeys() throws {
    let item = try item(#"{"host.name":"literal","host":{"name":"nested"},"a":{"b.c":{"d":1}}}"#)
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["host", "name"], item: item).sorted(), ["literal", "nested"])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["host.name"], item: item).sorted(), ["literal", "nested"])
    XCTAssertEqual(Results.getValueForKey(fieldParts: ["a", "b", "c", "d"], item: item), ["1"])
  }

  /// A small seeded generator, so the random documents are the same on every run.
  struct SeededRandom {
    var state: UInt64
    mutating func int(_ bound: Int) -> Int {
      state = state &* 6364136223846793005 &+ 1442695040888963407
      return Int((state >> 33) % UInt64(bound))
    }
  }

  static func randomValue(_ random: inout SeededRandom, depth: Int) -> Any {
    switch random.int(depth > 3 ? 9 : 12) {
    case 0: return ["hello", "", " ", "ü-ñ", "a, b", "true", "3"][random.int(7)]
    case 1: return [0, 1, -7, 42, 12345678901][random.int(5)]
    case 2: return [3.0, 3.14, -0.5, 1e20, 0.1, 2.5e-7][random.int(6)]
    case 3: return random.int(2) == 0
    case 4: return NSNull()
    case 5: return [String: Any]()
    case 6: return [Any]()
    case 7: return (0...random.int(3)).map { _ in [true, 1, "s", NSNull(), 2.5][random.int(5)] }
    case 8: return [random.int(2) == 0, random.int(2) == 0]
    case 9: return randomObject(&random, depth: depth + 1)
    case 10: return (0...random.int(3)).map { _ in randomObject(&random, depth: depth + 1) as Any }
    default: return (0...random.int(3)).map { _ in randomValue(&random, depth: depth + 1) }
    }
  }

  static func randomObject(_ random: inout SeededRandom, depth: Int) -> [String: Any] {
    let keys = ["a", "b", "c", "host", "name", "x.y", "host.name", "ü", "tags", "items", "id", "deep"]
    var object = [String: Any]()
    for _ in 0...random.int(5) {
      object[keys[random.int(keys.count)]] = randomValue(&random, depth: depth)
    }
    return object
  }

  /// Every value the table shows for a field is what the lookup finds for it, for fixture documents and
  /// random ones with every kind of value, nesting and dotted key.
  func testLookupMatchesFlattenedRows() throws {
    var pages = [[[String: Any]]]()
    for name in ["response.1", "response.2", "response.3", "response.5", "response.6", "response.9", "v5_search"] {
      pages.append(Search.getObjects(input: try SearchOpsTests().OpenFile(filename: name)).data)
    }
    var random = SeededRandom(state: 20261008)
    for _ in 0..<15 {
      // Round trip through JSON, so values are the NSNumber and NSNull a server response gives
      let documents = (0..<20).map { _ in Self.randomObject(&random, depth: 0) }
      let data = try JSONSerialization.data(withJSONObject: documents)
      pages.append(try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [[String: Any]]))
    }

    var compared = 0
    for documents in pages {
      let page = DocumentFlattener.flattenPage(documents)
      for (document, row) in zip(documents, page.rows) {
        let item = OrderedDictionary(uniqueKeys: document.keys, values: document.values)
        for field in page.fields {
          let found = Results.getValueForKey(fieldParts: field.parts, item: item)
          let shown = row[field.key] as? [String] ?? [""]
          // A field reached by a dotted key and a nested one can list its values in either order
          XCTAssertEqual(found.sorted(), shown.sorted(), "\(field.key) in \(document)")
          compared += 1
        }
      }
    }
    XCTAssertGreaterThan(compared, 5_000)
  }

  // MARK: - Showing values (iOS)

  func testJoinedValuesLeaveOutBlanks() {
    XCTAssertEqual(Results.joinedValues(["a", "b", "c"]), "a, b, c")
    XCTAssertEqual(Results.joinedValues(["", "a", "  ", "b"]), "a, b")
    XCTAssertEqual(Results.joinedValues(["0", "0"]), "0, 0")
    XCTAssertEqual(Results.joinedValues([""]), "")
    XCTAssertEqual(Results.joinedValues([]), "")
  }

  func testDocumentSummaryNamesEachFieldOnce() throws {
    let input = try item(#"{"tags":["a","b","c"],"host":{"ip":["10.0.0.1"]},"n":1,"none":null}"#)
    let headers = ["tags", "host.ip", "n", "none"].map {
      SquashedFieldsArray(squashedString: $0, fieldParts: $0.components(separatedBy: "."))
    }
    let summary = ElasticDocumentBuilder.exportValues(input: input, headers: headers, dateObj: nil)
    XCTAssertEqual(summary.map(\.value), ["tags", "a, b, c", "host.ip", "10.0.0.1", "n", "1"])
  }

  func testBooleanTextOnlyForBooleans() {
    XCTAssertEqual(DocumentFlattener.booleanText(true), "true")
    XCTAssertEqual(DocumentFlattener.booleanText(NSNumber(value: false)), "false")
    XCTAssertNil(DocumentFlattener.booleanText(1))
    XCTAssertNil(DocumentFlattener.booleanText(NSNumber(value: 0)))
    XCTAssertNil(DocumentFlattener.booleanText("true"))
    XCTAssertNil(DocumentFlattener.booleanText(nil))
    XCTAssertEqual(DocumentFlattener.booleanTexts([true, false]), ["true", "false"])
    XCTAssertNil(DocumentFlattener.booleanTexts([true, 1]))
    XCTAssertNil(DocumentFlattener.booleanTexts([Any]()))
  }
}
