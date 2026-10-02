// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

class SystemLogManagerCacheDirectoryTests: XCTestCase {
  var logManager: SystemLogManager!
  var fileManager: FileManager!
  var logsDirectoryURL: URL!
  
  override func setUpWithError() throws {
    super.setUp()
    fileManager = FileManager.default
    
    // Each test gets its own empty folder so parallel test runs can't collide
    logsDirectoryURL = fileManager.temporaryDirectory
      .appendingPathComponent("SystemLogTests-\(UUID().uuidString)", isDirectory: true)
    logManager = SystemLogManager(logsDirectory: logsDirectoryURL)
    try fileManager.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
  }
  
  override func tearDownWithError() throws {
    // Clean up by removing the log directory
    if fileManager.fileExists(atPath: logsDirectoryURL.path) {
      try fileManager.removeItem(at: logsDirectoryURL)
    }
    super.tearDown()
  }
  
  func testDefaultLogsDirectoryIsCachesLogFolder() throws {
    // Without an override, logs go to the "log" folder in the caches directory. Only the path is checked, no files are touched
    let cachesURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    let expected = cachesURL.appendingPathComponent("log", isDirectory: true)
    XCTAssertEqual(try SystemLogManager().resolveLogsDirectory(), expected)
  }
  
  func testFileCreationInCacheDirectory() {
    let content = "Test log entry"
    logManager.appendToFileInDocuments(content: content)
    
    // Check that the file exists in the caches directory
    do {
      let fileURLs = try fileManager.contentsOfDirectory(at: logsDirectoryURL, includingPropertiesForKeys: nil)
      XCTAssert(fileURLs.count == 1, "There should be exactly one log file in the directory.")
      
      let fileURL = fileURLs.first!
      XCTAssertTrue(fileURL.lastPathComponent.contains(".log"), "The log file should have a '.log' extension.")
      
      // Verify that the content of the file is correct
      let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
      XCTAssertTrue(fileContent.contains(content), "The content of the file should match the written string.")
      
    } catch {
      XCTFail("Failed to read from the directory: \(error)")
    }
  }
}
