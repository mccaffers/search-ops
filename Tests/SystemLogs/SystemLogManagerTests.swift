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
  var logsDirectoryURL: URL!
  
  override func setUp() {
    super.setUp()
    // Each test gets its own folder so parallel test runs can't delete each other's files
    logsDirectoryURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("SystemLogTests-\(UUID().uuidString)", isDirectory: true)
    logManager = SystemLogManager(logsDirectory: logsDirectoryURL)
  }
  
  override func tearDown() {
    try? FileManager.default.removeItem(at: logsDirectoryURL)
    super.tearDown()
  }
  
  func testFileCreationAndReading() {
    // Append new content to a log file
    // The write is synchronous, so the file is ready as soon as this returns
    logManager.appendToFileInDocuments(content: "Test log entry")
    
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
