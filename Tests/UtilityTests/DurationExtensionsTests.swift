// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Testing

@testable import Search_Ops

struct DurationExtensionsTests {

  @Test func zeroShowsMilliseconds() {
    #expect(Duration.zero.latencyLabel == "0 ms")
  }

  @Test func subSecondRoundsToWholeMilliseconds() {
    #expect(Duration.milliseconds(42).latencyLabel == "42 ms")
    #expect(Duration.microseconds(42_600).latencyLabel == "43 ms")
    #expect(Duration.milliseconds(999).latencyLabel == "999 ms")
  }

  @Test func oneSecondAndAboveShowsSeconds() {
    #expect(Duration.seconds(1).latencyLabel == "1.00 s")
    #expect(Duration.milliseconds(1234).latencyLabel == "1.23 s")
    #expect(Duration.seconds(65).latencyLabel == "65.00 s")
  }

  @Test func onlyLatencyOverOneSecondIsSlow() {
    #expect(!Duration.milliseconds(125).isSlowLatency)
    #expect(!Duration.seconds(1).isSlowLatency)
    #expect(Duration.milliseconds(1001).isSlowLatency)
    #expect(Duration.seconds(3).isSlowLatency)
  }
}
