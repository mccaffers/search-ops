// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import Foundation

public class TemporaryFile {
  
  public func CreateTempFile() {
    
    let directory = NSTemporaryDirectory()
    let fileName = NSUUID().uuidString

    // This returns a URL? even though it is an NSURL class method
    _ = NSURL.fileURL(withPathComponents: [directory, fileName])

  }
}
