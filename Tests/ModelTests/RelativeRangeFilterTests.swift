// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Testing

@testable import Search_Ops

struct RelativeRangeFilterTests {

  @Test func wholeNumberMakesARange() throws {
    let range = try #require(RelativeRangeFilter.from(text: "10", period: .Minutes))
    #expect(range.value == 10)
    #expect(range.period == .Minutes)
  }

  @Test func surroundingSpacesAreIgnored() throws {
    let range = try #require(RelativeRangeFilter.from(text: "  3 ", period: .Hours))
    #expect(range.value == 3)
    #expect(range.period == .Hours)
  }

  @Test func decimalsAreAllowed() throws {
    let range = try #require(RelativeRangeFilter.from(text: "1.5", period: .Days))
    #expect(range.value == 1.5)
  }

  @Test(arguments: ["", " ", "0", "-5", "abc", "10m", "nan", "inf"])
  func invalidTextMakesNoRange(text: String) {
    #expect(RelativeRangeFilter.from(text: text, period: .Minutes) == nil)
  }

  @Test func editableTextDropsTrailingZero() {
    #expect(RelativeRangeFilter.editableText(for: 10) == "10")
    #expect(RelativeRangeFilter.editableText(for: 5.0) == "5")
    #expect(RelativeRangeFilter.editableText(for: 1.5) == "1.5")
  }
}
