// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public class SystemLogManager {
  
  /// Appends the given content to a file in the "log" folder within the caches directory.
   /// The file name is automatically generated based on the current date.
   /// If the file size exceeds 1MB, a new file is created with a sequence number.
   /// - Parameter content: The string content to be written to the file.
  func appendToFileInDocuments(content: String) {
    let fileManager = FileManager.default
    do {
      // Retrieve the URL for the caches directory.
      let cachesURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      
      // Construct the URL for the "log" folder within the caches directory.
      let logsDirectoryURL = cachesURL.appendingPathComponent("log", isDirectory: true)
      
      // Ensure the "log" directory exists.
      if !fileManager.fileExists(atPath: logsDirectoryURL.path) {
        try fileManager.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
      }
      
      // Generate a file name using the current date.
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyyMMdd"
      var fileName = dateFormatter.string(from: Date()) + ".log"
      
      // Append the generated file name to the logs directory path to create the full file path.
      var fileURL = logsDirectoryURL.appendingPathComponent(fileName)
      
      // Check if the file size exceeds 1MB and create a new file if necessary.
      if fileManager.fileExists(atPath: fileURL.path) {
        let fileSize = try fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? UInt64
        if let fileSize = fileSize, fileSize > 1_000_000 { // File size exceeds 1MB
          // Generate a new file with a sequence number to avoid overwriting.
          var sequence = 1
          repeat {
            fileName = "\(dateFormatter.string(from: Date()))_\(sequence).log"
            fileURL = logsDirectoryURL.appendingPathComponent(fileName)
            sequence += 1
          } while fileManager.fileExists(atPath: fileURL.path)
        }
      }
      
      // Write or append the content.
      if !fileManager.fileExists(atPath: fileURL.path) {
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
      } else {
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        fileHandle.seekToEndOfFile() // Position the file handle to the end of the file.
        if let data = content.data(using: .utf8) {
          fileHandle.write(data) // Write the new data to the file.
        }
        fileHandle.closeFile() // Close the file to finalize the write operation.
      }
      
//      print("Content appended successfully at: \(fileURL.path)")
    } catch {
//      print("Error handling file operations: \(error)")
    }
  }
  
  func readFromFileInDocuments(fileName: String) -> String? {
    
    let fileManager = FileManager.default
    do {
      // Get the URL for the documents directory
      let documentsURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      
      // Specify the "log" folder within the documents directory
      let logsDirectoryURL = documentsURL.appendingPathComponent("log", isDirectory: true)
      
      // Append the filename to the logs directory path to get the file URL
      let fileURL = logsDirectoryURL.appendingPathComponent(fileName)
      
      // Check if the file exists
      if fileManager.fileExists(atPath: fileURL.path) {
        // Read content from the file
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return content
      } else {
        print("File does not exist.")
        return nil
      }
    } catch {
      print("Error reading file: \(error)")
      return nil
    }
    
  }
  
  /// Retrieves a list of all the files in the "log" folder within the caches directory.
  /// - Returns: An array of file names as strings. Returns an empty array if there are no files or if an error occurs.
  func listLogFiles() -> [String] {
    let fileManager = FileManager.default
    do {
      // Retrieve the URL for the caches directory.
      let documentsURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      
      // Construct the URL for the "log" folder within the documents directory.
      let logsDirectoryURL = documentsURL.appendingPathComponent("log", isDirectory: true)
      
      // Check if the "log" directory exists; if not, return an empty array as there are no files to list.
      guard fileManager.fileExists(atPath: logsDirectoryURL.path) else {
        return []
      }
      
      // Retrieve the contents of the "log" directory.
      let fileURLs = try fileManager.contentsOfDirectory(at: logsDirectoryURL, includingPropertiesForKeys: nil)
      
      // Extract the file names from the URLs and return them.
      return fileURLs.map { $0.lastPathComponent }
    } catch {
      print("Error retrieving log files: \(error)")
      return []
    }
  }
  
  /// Clears all files from the "log" folder within the caches directory, effectively emptying the directory without removing it.
  func clearLogDirectory() {
    let fileManager = FileManager.default
    do {
      // Retrieve the URL for the caches directory.
      let documentsURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      
      // Construct the URL for the "log" folder within the caches directory.
      let logsDirectoryURL = documentsURL.appendingPathComponent("log", isDirectory: true)
      
      // Check if the "log" directory exists; if not, there's nothing to clear.
      guard fileManager.fileExists(atPath: logsDirectoryURL.path) else {
        print("Log directory does not exist, no need to clear.")
        return
      }
      
      // Retrieve the contents of the "log" directory.
      let fileURLs = try fileManager.contentsOfDirectory(at: logsDirectoryURL, includingPropertiesForKeys: nil)
      
      // Iterate over each file in the directory and delete it.
      for fileURL in fileURLs {
        try fileManager.removeItem(at: fileURL)
        print("Deleted file: \(fileURL.path)")
      }
      
      print("All files have been deleted from the log directory.")
    } catch {
      print("Error clearing log directory: \(error)")
    }
  }
  
  /// Calculates the total size of the "log" folder within the caches directory.
  /// Returns the size in bytes as an Int.
  func getSizeOfLogFolder() -> Int {
    let fileManager = FileManager.default
    do {
      let documentsURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      let logsDirectoryURL = documentsURL.appendingPathComponent("log", isDirectory: true)
      
      // Check if the log directory exists
      guard fileManager.fileExists(atPath: logsDirectoryURL.path) else {
        print("Log directory does not exist.")
        return 0
      }
      
      // Retrieve the directory contents
      let fileURLs = try fileManager.contentsOfDirectory(at: logsDirectoryURL, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles)
      
      // Sum up the file sizes
      let totalSize = try fileURLs.reduce(0) { (size, fileURL) -> Int in
        let fileAttributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        if let fileSize = fileAttributes[.size] as? NSNumber {
          return size + fileSize.intValue
        } else {
          return size
        }
      }
      
      return totalSize
      
    } catch {
      print("Failed to calculate the size of the log folder: \(error)")
      return 0
    }
  }
}
