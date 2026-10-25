// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

#if os(iOS)
import Testing

@testable import Search_Ops

struct ReleaseNotesLaunchTests {

  @Test func dueWhenNotSeen() {
    #expect(MainRoutingView.releaseNotesDue(lastSeen: "", keyUnavailable: false))
    #expect(MainRoutingView.releaseNotesDue(lastSeen: "3.0", keyUnavailable: false))
  }

  @Test func notDueOnceSeen() {
    #expect(!MainRoutingView.releaseNotesDue(lastSeen: MainRoutingView.currentReleaseNotes, keyUnavailable: false))
  }

  // The "Couldn't Load Your Data" alert can't show while the release notes sheet is up
  @Test func notDueWhenKeyUnavailable() {
    #expect(!MainRoutingView.releaseNotesDue(lastSeen: "", keyUnavailable: true))
    #expect(!MainRoutingView.releaseNotesDue(lastSeen: "3.0", keyUnavailable: true))
  }
}
#endif
