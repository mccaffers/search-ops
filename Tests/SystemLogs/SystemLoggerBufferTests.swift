// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

final class SystemLoggerBufferTests: XCTestCase {
  
  var logWriter: SystemLogBufferWritter!
  
  override func setUp() {
    super.setUp()
    logWriter = SystemLogBufferWritter()
    // Clean up test files if any from previous tests
    cleanUpTestFiles()
  }
  
  override func tearDown() {
    // Clean up after each test
    cleanUpTestFiles()
    super.tearDown()
  }
  
  /// Cleans up the "log" directory from the caches directory, removing all contained test files and the directory itself.
  func cleanUpTestFiles() {
    let fileManager = FileManager.default
    do {
      // Fetch the URL for the caches directory.
      let documentsURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      // Create the full path to the "log" directory.
      let logDirectoryURL = documentsURL.appendingPathComponent("log")
      
      // Check if the "log" directory exists and remove it if it does.
      if fileManager.fileExists(atPath: logDirectoryURL.path) {
        try fileManager.removeItem(at: logDirectoryURL)
      }
    } catch {
      print("Failed to clean up the log directory: \(error)")
    }
  }
  
  /// Tests the logging of a message with the INFO level to ensure the buffer correctly includes
  /// both the log level and the content. This also verifies that the asynchronous appending functionality
  /// works as expected.
  func testAppendToFileWithBufferInfoLevel() {
    // Set up an expectation for the asynchronous operation.
    let expectation = self.expectation(description: "Buffer update for INFO level")
    
    // Perform the log appending operation.
    logWriter.appendToFileWithBuffer(content: "Test INFO", level: .info) {
      // Verify that the buffer includes the correct INFO log level and message content.
      XCTAssertTrue(SystemLogBufferWritter.buffer.contains("INFO"), "Buffer should contain the 'INFO' log level.")
      XCTAssertTrue(SystemLogBufferWritter.buffer.contains("Test INFO"), "Buffer should contain the message content.")
      expectation.fulfill() // Fulfill the expectation upon successful verification.
    }
    
    // Wait for the expectations to be fulfilled with a timeout to avoid indefinite waiting.
    waitForExpectations(timeout: 2.0)
  }
  
  /// Tests the DEBUG level logging to ensure the buffer captures the specified log level and message.
  func testAppendToFileWithBufferDebugLevel() {
    let expectation = self.expectation(description: "Buffer update for DEBUG level")
    
    logWriter.appendToFileWithBuffer(content: "Test DEBUG", level: .debug) {
      XCTAssertTrue(SystemLogBufferWritter.buffer.contains("DEBUG"), "Buffer should contain the 'DEBUG' log level.")
      XCTAssertTrue(SystemLogBufferWritter.buffer.contains("Test DEBUG"), "Buffer should contain the message content.")
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 2.0)
  }
  
  /// Tests the WARN level logging to confirm that the log entries are appended with correct
  /// severity labels and content in the buffer.
  func testAppendToFileWithBufferWarnLevel() {
    let expectation = self.expectation(description: "Buffer update for WARN level")
    
    logWriter.appendToFileWithBuffer(content: "Test WARN", level: .warn) {
      XCTAssertTrue(SystemLogBufferWritter.buffer.contains("WARN"), "Buffer should contain the 'WARN' log level.")
      XCTAssertTrue(SystemLogBufferWritter.buffer.contains("Test WARN"), "Buffer should contain the message content.")
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 2.0)
  }
  
  /// Tests the FATAL level logging to check if severe messages are logged correctly.
  /// This ensures critical messages are highlighted as expected in the buffer.
  func testAppendToFileWithBufferFatalLevel() {
    let expectation = self.expectation(description: "Buffer update for FATAL level")
    
    logWriter.appendToFileWithBuffer(content: "Test FATAL", level: .fatal) {
      XCTAssertTrue(SystemLogBufferWritter.buffer.contains("FATAL"), "Buffer should contain the 'FATAL' log level.")
      XCTAssertTrue(SystemLogBufferWritter.buffer.contains("Test FATAL"), "Buffer should contain the message content.")
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 2.0)
  }
  
  /// Tests the buffer writing mechanism to ensure it correctly handles multiple entries and timing.
  func testAppendToFileWithBuffer() {
    // Append two entries to the buffer.
    logWriter.appendToFileWithBuffer(content: "First log entry")
    logWriter.appendToFileWithBuffer(content: "Second log entry")
    
    // Create an expectation to wait for the buffer to potentially flush due to the interval setting.
    let bufferAwait = XCTestExpectation(description: "Wait for buffer to flush")
    DispatchQueue.main.asyncAfter(deadline: .now() + 11) { bufferAwait.fulfill() }
    wait(for: [bufferAwait], timeout: 12)
    
    // Append a third entry after the buffer has likely been flushed.
    self.logWriter.appendToFileWithBuffer(content: "Third log entry")
    
    // Create another expectation to allow for the third entry to be processed.
    let asyncWait = XCTestExpectation(description: "Wait with minimal delay")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { asyncWait.fulfill() }
    wait(for: [asyncWait], timeout: 2)
    
    // List files in the log directory and verify that a new file has been created
    let files = SystemLogManager().listLogFiles()
    XCTAssertEqual(files.count, 1, "There should be exactly one log file in the directory.")
    
    // Verify that the created file contains the expected content
    if let fileName = files.first {
      if let content = SystemLogManager().readFromFileInDocuments(fileName: fileName) {
        XCTAssertTrue(content.contains("First log entry"), "First log entry should be written to the file.")
        XCTAssertTrue(content.contains("Second log entry"), "Second log entry should be written to the file.")
      } else {
        XCTFail("The file was expected to contain content but was empty or could not be read.")
      }
    } else {
      XCTFail("No file was found after writing to the log directory.")
    }
  }
  
}
