// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// A simplified logger class that extends `SystemLogBufferWritter` to provide specific logging functionalities.
/// This class serves as a convenient wrapper around the buffer writer functionality, providing a simplified
/// interface for logging messages and listing log files. Also provides access to `SystemLogManager` methods
public class SystemLogger : SystemLogBufferWritter {
  
  public override init() {
    // For a type that’s defined as public, the default initializer is considered internal.
    // If you want a public type to be initializable with a no-argument initializer when used in another module,
    // you must explicitly provide a public no-argument initializer yourself as part of the type’s definition.
    // Reference: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/
    // SonarCloud - swift:S1186
  }
  
  /// Appends a message to the log file.
  /// - Parameter content: The string content that will be logged to the file.
  /// This method abstracts away the details of how content is logged, allowing easy logging with a single method call.
  public func message(_ content: String, level: LogLevel = .info) {
    print(content)
    self.appendToFileWithBuffer(content: content, level:level) // Utilizes inherited method to append content to the log buffer.
  }
  
  public func flush() {
    self.flushBuffer()
  }
   
  /// Retrieves a list of all log files currently stored.
  /// - Returns: An array of strings, where each string is the name of a log file.
  /// This method provides an interface to list all files, which could be useful for managing logs or displaying log information.
  public func listFiles() -> [String] {
    return self.listLogFiles() // Calls inherited method to get the list of all log files.
  }
  
  public func readLog(_ filename: String) -> String? {
    return self.readFromFileInDocuments(fileName: filename)
  }
  
  /// Clears all log files
  public func clearLogs()  {
    return self.clearLogDirectory()
  }
}
