// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

class SystemLogManagerSizeTests: XCTestCase {
  var logManager: SystemLogManager!
  var fileManager: FileManager!
  var logsDirectoryURL: URL!
  
  override func setUpWithError() throws {
    super.setUp()
    logManager = SystemLogManager()
    fileManager = FileManager.default
    
    let cachesDirectoryURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    logsDirectoryURL = cachesDirectoryURL.appendingPathComponent("log", isDirectory: true)
    
    // Ensure the directory is empty before each test
    if fileManager.fileExists(atPath: logsDirectoryURL.path) {
      try fileManager.removeItem(at: logsDirectoryURL)
    }
    try fileManager.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
  }
  
  override func tearDownWithError() throws {
    // Clean up by removing the log directory
    if fileManager.fileExists(atPath: logsDirectoryURL.path) {
      try fileManager.removeItem(at: logsDirectoryURL)
    }
    super.tearDown()
  }
  
  func testGetSizeOfEmptyLogFolder() throws {
    // Test that an empty log directory has a size of 0 bytes
    XCTAssertEqual(logManager.getSizeOfLogFolder(), 0, "Size of an empty log folder should be 0 bytes.")
  }
  
  func testGetSizeOfLogFolderWithFiles() throws {
    // Create test files in the log directory
    let file1 = logsDirectoryURL.appendingPathComponent("test1.log")
    let file2 = logsDirectoryURL.appendingPathComponent("test2.log")
    let content1 = "Hello, world!" // 13 bytes
    let content2 = "Hello, Swift!" // 13 bytes
    try content1.write(to: file1, atomically: true, encoding: .utf8)
    try content2.write(to: file2, atomically: true, encoding: .utf8)
    
    // The size calculation may differ slightly based on filesystem storage techniques, encoding, and metadata.
    // We are testing if the size reported is greater than the content size due to filesystem overhead.
    let reportedSize = logManager.getSizeOfLogFolder()
    XCTAssertTrue(reportedSize >= 26, "Reported size should be at least the sum of the content sizes.")
  }
}
