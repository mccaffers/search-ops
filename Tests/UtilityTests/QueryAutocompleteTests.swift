// SearchOps Source Code
// Unit tests for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import Testing

@testable import Search_Ops

struct QueryAutocompleteTests {

  func field(_ name: String, type: String = "keyword") -> SquashedFieldsArray {
    let field = SquashedFieldsArray(squashedString: name, fieldParts: name.components(separatedBy: "."))
    field.type = type
    return field
  }

  /// The token at the end of `text`
  func tokenAtEnd(_ text: String) -> QueryAutocompleteToken? {
    QueryAutocomplete.token(in: text, cursor: (text as NSString).length)
  }

  // MARK: - Token

  @Test func findsTheWordAtTheEnd() throws {
    let token = try #require(tokenAtEnd("status:200 AND ho"))
    #expect(token.prefix == "ho")
    #expect(token.range == NSRange(location: 15, length: 2))
  }

  @Test func findsAWordOnItsOwn() throws {
    let token = try #require(tokenAtEnd("ho"))
    #expect(token.prefix == "ho")
    #expect(token.range == NSRange(location: 0, length: 2))
  }

  @Test func coversTheWholeWordWhenTheCursorIsInside() throws {
    let token = try #require(QueryAutocomplete.token(in: "error AND hostname", cursor: 12))
    #expect(token.prefix == "ho")
    #expect(token.range == NSRange(location: 10, length: 8))
  }

  @Test func startsAfterABracket() throws {
    let token = try #require(tokenAtEnd("(status:200 OR (me"))
    #expect(token.prefix == "me")
    #expect(token.range.location == 16)
  }

  @Test func leavesModifiersOutOfTheRange() throws {
    for text in ["-ho", "+ho", "!ho"] {
      let token = try #require(tokenAtEnd(text), "\(text)")
      #expect(token.prefix == "ho", "\(text)")
      #expect(token.range == NSRange(location: 1, length: 2), "\(text)")
    }
  }

  @Test func noTokenWithoutTypedText() {
    #expect(tokenAtEnd("") == nil)
    #expect(tokenAtEnd("status:200 ") == nil)
    #expect(tokenAtEnd("-") == nil)
    #expect(QueryAutocomplete.token(in: "host", cursor: 0) == nil)
  }

  @Test func noTokenForAValue() {
    #expect(tokenAtEnd("host.name:web") == nil)
    #expect(tokenAtEnd("host.name:") == nil)
    #expect(QueryAutocomplete.token(in: "host:web", cursor: 2) == nil)
  }

  @Test func noTokenInsideQuotes() {
    #expect(tokenAtEnd("message:\"disk fu") == nil)
    #expect(tokenAtEnd("\"disk") == nil)
    #expect(tokenAtEnd("message:\"disk \\\" fu") == nil)
    #expect(tokenAtEnd("message:\"disk full\" AND ho") != nil)
  }

  @Test func noTokenForOperators() {
    for op in ["AND", "OR", "NOT", "&&", "||"] {
      #expect(tokenAtEnd("error \(op)") == nil, "\(op)")
    }
    #expect(tokenAtEnd("error and") != nil)
  }

  @Test func noTokenForACursorOutsideTheText() {
    #expect(QueryAutocomplete.token(in: "host", cursor: 5) == nil)
    #expect(QueryAutocomplete.token(in: "host", cursor: -1) == nil)
  }

  @Test func countsEmojiAsTwoUTF16Units() throws {
    // 🔥 is two UTF-16 units, so "ho" starts at 3
    let token = try #require(tokenAtEnd("🔥 ho"))
    #expect(token.range == NSRange(location: 3, length: 2))
    #expect(token.prefix == "ho")
  }

  // MARK: - Suggestions

  @Test func ranksPrefixThenSegmentThenContains() {
    let fields = [field("username"), field("host.name"), field("name"), field("names.first"), field("message")]
    let names = QueryAutocomplete.suggestions(for: "na", fields: fields).map(\.text)
    #expect(names == ["name", "names.first", "host.name", "username"])
  }

  @Test func matchesCaseInsensitively() {
    let names = QueryAutocomplete.suggestions(for: "HO", fields: [field("Host.Name")]).map(\.text)
    #expect(names == ["Host.Name"])
  }

  @Test func dropsTheExactField() {
    let names = QueryAutocomplete.suggestions(for: "host", fields: [field("host"), field("host.name")]).map(\.text)
    #expect(names == ["host.name"])
  }

  @Test func skipsObjectsDuplicatesAndEmptyNames() {
    let fields = [field("host", type: "object"), field("hosts", type: "nested"), field(""),
                  field("host.name"), field("host.name")]
    let names = QueryAutocomplete.suggestions(for: "ho", fields: fields).map(\.text)
    #expect(names == ["host.name"])
  }

  @Test func matchesDataViewLabels() {
    let fields = [field("http.response.status_code", type: "long"), field("client.ip", type: "ip")]
    let labels = ["http.response.status_code": "Status", "client.ip": ""]
    let suggestions = QueryAutocomplete.suggestions(for: "stat", fields: fields, labels: labels)
    #expect(suggestions == [QueryAutocompleteSuggestion(text: "http.response.status_code", type: "long", label: "Status")])
  }

  @Test func capsTheNumberOfSuggestions() {
    let fields = (0..<80).map { field("field\($0)") }
    #expect(QueryAutocomplete.suggestions(for: "f", fields: fields).count == QueryAutocomplete.maxSuggestions)
  }

  @Test func noSuggestionsForAnEmptyPrefix() {
    #expect(QueryAutocomplete.suggestions(for: "", fields: [field("host")]).isEmpty)
  }

  // MARK: - Apply

  @Test func replacesTheWordWithTheFieldAndAColon() throws {
    let text = "status:200 AND ho"
    let token = try #require(tokenAtEnd(text))
    let result = QueryAutocomplete.apply(field: "host.name", to: text, token: token)
    #expect(result.text == "status:200 AND host.name:")
    #expect(result.cursor == 25)
  }

  @Test func replacesTheRestOfTheWordAfterTheCursor() throws {
    let text = "hostna AND error"
    let token = try #require(QueryAutocomplete.token(in: text, cursor: 2))
    let result = QueryAutocomplete.apply(field: "host.name", to: text, token: token)
    #expect(result.text == "host.name: AND error")
    #expect(result.cursor == 10)
  }

  @Test func keepsTheModifier() throws {
    let token = try #require(tokenAtEnd("-ho"))
    let result = QueryAutocomplete.apply(field: "host.name", to: "-ho", token: token)
    #expect(result.text == "-host.name:")
    #expect(result.cursor == 11)
  }

  @Test func escapesReservedCharacters() {
    #expect(QueryAutocomplete.escapeField("@timestamp") == "@timestamp")
    #expect(QueryAutocomplete.escapeField("user-agent") == "user-agent")
    #expect(QueryAutocomplete.escapeField("-start") == "\\-start")
    #expect(QueryAutocomplete.escapeField("first name") == "first\\ name")
    #expect(QueryAutocomplete.escapeField("a/b:c") == "a\\/b\\:c")
  }

  // MARK: - Value context

  /// The value context at the end of `text`
  func valueAtEnd(_ text: String) -> (field: String, token: QueryAutocompleteToken)? {
    QueryAutocomplete.valueToken(in: text, cursor: (text as NSString).length)
  }

  @Test func findsAnEmptyValueAfterTheColon() throws {
    let value = try #require(valueAtEnd("status:200 AND env:"))
    #expect(value.field == "env")
    #expect(value.token.prefix == "")
    #expect(value.token.range == NSRange(location: 19, length: 0))
  }

  @Test func findsAPartValue() throws {
    let value = try #require(valueAtEnd("host.name:we"))
    #expect(value.field == "host.name")
    #expect(value.token.prefix == "we")
    #expect(value.token.range == NSRange(location: 10, length: 2))
  }

  @Test func coversTheWholeValueWhenTheCursorIsInside() throws {
    let value = try #require(QueryAutocomplete.valueToken(in: "env:demo AND x", cursor: 6))
    #expect(value.field == "env")
    #expect(value.token.prefix == "de")
    #expect(value.token.range == NSRange(location: 4, length: 4))
  }

  @Test func leavesModifiersOffTheField() throws {
    #expect(try #require(valueAtEnd("-env:de")).field == "env")
    #expect(try #require(valueAtEnd("(env:de")).field == "env")
  }

  @Test func findsAnUnfinishedQuotedValue() throws {
    let value = try #require(valueAtEnd("region:\"eu we"))
    #expect(value.field == "region")
    #expect(value.token.prefix == "eu we")
    #expect(value.token.range == NSRange(location: 7, length: 6))
  }

  @Test func coversTheClosingQuote() throws {
    let text = "region:\"eu west\" AND x"
    let value = try #require(QueryAutocomplete.valueToken(in: text, cursor: 10))
    #expect(value.token.prefix == "eu")
    #expect(value.token.range == NSRange(location: 7, length: 9))
  }

  @Test func noValueContextOutsideAValue() {
    #expect(QueryAutocomplete.valueToken(in: "env:demo", cursor: 2) == nil)
    #expect(valueAtEnd("region:\"eu west\"") == nil)
    #expect(valueAtEnd("env:\"demo\"") == nil)
    #expect(valueAtEnd("\"disk fu") == nil)
    #expect(valueAtEnd(":de") == nil)
    #expect(valueAtEnd("_exists_:ho") == nil)
    #expect(valueAtEnd("env") == nil)
    #expect(valueAtEnd("status:[1") == nil)
  }

  @Test func contextPrefersTheFieldName() {
    #expect(QueryAutocomplete.context(in: "ho", cursor: 2) == .field(QueryAutocompleteToken(range: NSRange(location: 0, length: 2), prefix: "ho")))
    #expect(QueryAutocomplete.context(in: "env:", cursor: 4) == .value(field: "env", token: QueryAutocompleteToken(range: NSRange(location: 4, length: 0), prefix: "")))
    #expect(QueryAutocomplete.context(in: "env:demo ", cursor: 9) == nil)
  }

  // MARK: - Value suggestions

  @Test func keepsAllValuesInOrderForAnEmptyPrefix() {
    let names = QueryAutocomplete.valueSuggestions(for: "", values: ["prod", "demo", "", "prod"]).map(\.text)
    #expect(names == ["prod", "demo"])
  }

  @Test func ranksStartingValuesBeforeContaining() {
    let suggestions = QueryAutocomplete.valueSuggestions(for: "de", values: ["code", "demo", "dev", "de", "prod"])
    #expect(suggestions.map(\.text) == ["demo", "dev", "code"])
    #expect(suggestions.allSatisfy { $0.kind == .value })
  }

  // MARK: - Apply value

  @Test func insertsAPlainValueAndASpace() throws {
    let text = "env:de"
    let value = try #require(valueAtEnd(text))
    let result = QueryAutocomplete.apply(value: "demo", to: text, token: value.token)
    #expect(result.text == "env:demo ")
    #expect(result.cursor == 9)
  }

  @Test func reusesAFollowingSpace() throws {
    let text = "env:de AND x"
    let value = try #require(QueryAutocomplete.valueToken(in: text, cursor: 6))
    let result = QueryAutocomplete.apply(value: "demo", to: text, token: value.token)
    #expect(result.text == "env:demo AND x")
    #expect(result.cursor == 9)
  }

  @Test func replacesAQuotedValue() throws {
    let text = "region:\"eu we"
    let value = try #require(valueAtEnd(text))
    let result = QueryAutocomplete.apply(value: "eu west", to: text, token: value.token)
    #expect(result.text == "region:\"eu west\" ")
    #expect(result.cursor == 17)
  }

  @Test func quotesValuesThatNeedIt() {
    #expect(QueryAutocomplete.formatValue("demo") == "demo")
    #expect(QueryAutocomplete.formatValue("10.0.0.1") == "10.0.0.1")
    #expect(QueryAutocomplete.formatValue("200") == "200")
    #expect(QueryAutocomplete.formatValue("true") == "true")
    #expect(QueryAutocomplete.formatValue("web-1") == "\"web-1\"")
    #expect(QueryAutocomplete.formatValue("-5") == "\"-5\"")
    #expect(QueryAutocomplete.formatValue("eu west") == "\"eu west\"")
    #expect(QueryAutocomplete.formatValue("AND") == "\"AND\"")
    #expect(QueryAutocomplete.formatValue("say \"hi\"") == "\"say \\\"hi\\\"\"")
    #expect(QueryAutocomplete.formatValue("a\\b") == "\"a\\\\b\"")
  }
}
