// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

class SystemLogManagerTests: XCTestCase {
  var logManager: SystemLogManager!
  
  override func setUp() {
    super.setUp()
    logManager = SystemLogManager()
    // Clear any existing files to start fresh
    logManager.clearLogDirectory()
  }
  
  override func tearDown() {
    // Optionally clear files after tests to clean up
    logManager.clearLogDirectory()
    super.tearDown()
  }
  
  func testFileCreationAndReading() {
    // Append new content to a log file
    logManager.appendToFileInDocuments(content: "Test log entry")
    
    // Allow time for the file system operations to complete
    // in practice though, we use a buffer and async to do this behind the scenes
    sleep(1)
    
    // List files in the log directory and verify that a new file has been created
    let files = logManager.listLogFiles()
    XCTAssertEqual(files.count, 1, "There should be exactly one log file in the directory.")
    
    // Verify that the created file contains the expected content
    if let fileName = files.first {
      if let content = logManager.readFromFileInDocuments(fileName: fileName) {
        XCTAssertTrue(content.contains("Test log entry"), "The content of the file should match the written string.")
      } else {
        XCTFail("The file was expected to contain content but was empty or could not be read.")
      }
    } else {
      XCTFail("No file was found after writing to the log directory.")
    }
  }
}
