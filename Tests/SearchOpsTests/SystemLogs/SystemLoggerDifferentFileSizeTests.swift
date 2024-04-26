// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import SearchOps

class SystemLoggerDifferentFileSizeTests: XCTestCase {
  var logManager: SystemLogManager!
  let fileManager = FileManager.default
  var testLogsDirectory: URL!
  
  override func setUp() {
    super.setUp()
    logManager = SystemLogManager()
    setupTestLogsDirectory()
  }
  
  override func tearDown() {
    try? fileManager.removeItem(at: testLogsDirectory)
    super.tearDown()
  }
  
  func setupTestLogsDirectory() {
    let cachesDirectory = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    testLogsDirectory = cachesDirectory.appendingPathComponent("log")
    if !fileManager.fileExists(atPath: testLogsDirectory.path) {
      try! fileManager.createDirectory(at: testLogsDirectory, withIntermediateDirectories: true, attributes: nil)
    }
  }
  
  func testAppendToFileWhenFileIsUnder1MB() {
    // Append two small entries to the log file.
    logManager.appendToFileInDocuments(content: "Small log entry")
    logManager.appendToFileInDocuments(content: "Another small entry")
    
    // Retrieve the list of log files.
    let files = logManager.listLogFiles()
    
    // Check there is exactly one log file in the directory.
    XCTAssertEqual(files.count, 1, "There should be exactly one log file in the directory.")
    
    // Ensure that we can retrieve the file and its contents.
    if let fileName = files.first {
      if let resultContent = logManager.readFromFileInDocuments(fileName: fileName) {
        // Check that the content includes both log entries.
        XCTAssertTrue(resultContent.contains("Small log entry"), "Initial content should be present.")
        XCTAssertTrue(resultContent.contains("Another small entry"), "Appended content should be present.")
      } else {
        // Fail the test if the content could not be read.
        XCTFail("Failed to read content from the file named \(fileName).")
      }
    } else {
      // Fail the test if no file name could be retrieved.
      XCTFail("No log file found.")
    }
  }
  
  func testAppendToFileWhenFileIsOver1MB() {
    
    // Append two small entries to the log file.
    logManager.appendToFileInDocuments(content: "Small log entry")
    logManager.appendToFileInDocuments(content: String(repeating: "a", count: 1_000_001)) // More than 1MB
    logManager.appendToFileInDocuments(content: "New entry after large file")
    
    let filesInDirectory = logManager.listLogFiles()
    XCTAssertTrue(filesInDirectory.count > 1, "A new file should be created because the original was over 1MB")
  }
}
