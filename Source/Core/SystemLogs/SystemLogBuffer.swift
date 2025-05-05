// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// Manages a buffer for system log entries and writes them to a file at regular intervals.
public class SystemLogBufferWritter : SystemLogManager {

  // Holds accumulated log entries as a single string.
  public static var buffer: String = ""
  
  // Stores the date and time when the buffer was last flushed.
  public static var lastFlushDate: Date? = nil
  
  // Defines the minimum time interval between consecutive flushes to the file.
  private let interval: TimeInterval = 10  // 10 seconds
  
  // The dispatch queue used for synchronizing write operations to the buffer.
  public static let queue = DispatchQueue(label: "searchops.app.bufferedlogwriter")
  
  // An array to temporarily hold log entries; currently not in use.
  private var logBuffer: [String] = []
  
  /// Appends the given content to the buffer and initiates a flush if conditions are met.
  /// - Parameters:
  ///   - fileName: The name of the file to which the content will be written.
  ///   - content: The log content to append to the buffer.
  func appendToFileWithBuffer(content: String, level: LogLevel = .info, completion: (() -> Void)? = nil) {
    SystemLogBufferWritter.queue.async {
      // Create a date formatter to format the date string.
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "HH:mm:ss"
      
      // Get the current date and format it as a string.
      let dateString = dateFormatter.string(from: Date())
      
      // Combine the date string with the original content, followed by a newline.
      let contentWithDate = "\(dateString) | \(level.rawValue) | \(content)\n"
      // Add the new content with the date to the buffer.
      SystemLogBufferWritter.buffer += contentWithDate
      
      // Check if the buffer should be flushed to the file.
      self.maybeFlushBuffer()
      completion?()
    }
  }
  
  /// Evaluates whether the buffer should be flushed based on the time since the last flush.
  /// - Parameter fileName: The name of the file to flush the buffer to.
  func maybeFlushBuffer() {
    let now = Date()
    // Check if the time since the last flush is less than the set interval.
    if let lastFlushDate = SystemLogBufferWritter.lastFlushDate, now.timeIntervalSince(lastFlushDate) < interval {      return
    }
    
    flushBuffer()  // Proceeds to flush the buffer.
    SystemLogBufferWritter.lastFlushDate = now  // Updates the time of the last flush.
  }
  
  /// Writes the buffer to the specified file and then clears the buffer.
  /// - Parameter fileName: The name of the file to which the buffer will be written.
  func flushBuffer() {
    if !SystemLogBufferWritter.buffer.isEmpty {
      SystemLogManager().appendToFileInDocuments(content: SystemLogBufferWritter.buffer)
      SystemLogBufferWritter.buffer = ""  // Clears the buffer after writing.
    }
  }
}
