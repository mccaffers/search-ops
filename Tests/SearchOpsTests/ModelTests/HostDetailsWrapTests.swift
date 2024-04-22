// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

final class HostDetailsWrapTests: XCTestCase {

  // Test initialization with nil.
  func testInitializationWithNil() {
      let hostDetailsWrap = HostDetailsWrap()
      XCTAssertNil(hostDetailsWrap.item, "HostDetailsWrap should initialize with nil item if no item is provided.")
  }

  // Test initialization with a HostDetails object.
  func testInitializationWithHostDetails() {
      let hostDetails = HostDetails()  // Assuming HostDetails can be initialized this way.
      let hostDetailsWrap = HostDetailsWrap(item: hostDetails)
      XCTAssertNotNil(hostDetailsWrap.item, "HostDetailsWrap should not be nil when initialized with a HostDetails object.")
      XCTAssertEqual(hostDetailsWrap.item, hostDetails, "HostDetailsWrap item should be the same as the one provided at initialization.")
  }

  // Test the @Published property to check if changes are being published.
  func testPublishedPropertyChanges() {
      let hostDetailsWrap = HostDetailsWrap()
      let expectation = XCTestExpectation(description: "Observer should be notified of changes")
      
      let observer = hostDetailsWrap.objectWillChange.sink {
          expectation.fulfill()  // Fulfill the expectation when the change is published.
      }

      hostDetailsWrap.item = HostDetails()  // Change the item.

      wait(for: [expectation], timeout: 1.0)  // Wait for the expectation to be fulfilled.
      observer.cancel()  // Don't forget to cancel the observer.
  }

}
