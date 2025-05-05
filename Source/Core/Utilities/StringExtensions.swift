// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

extension String {
  var isInt: Bool {
    return Int(self) != nil
  }
  
  public func truncated(to maxLength: Int, addEllipsis: Bool = true) -> String {
    if self.count > maxLength {
      let endIndex = maxLength - (addEllipsis ? 3 : 0)
      return endIndex > 0 ? String(self.prefix(endIndex)) + (addEllipsis ? "..." : "") : ""
    } else {
      return self
    }
  }
  
  
  public func prettifyJSON() -> String {
    
    // Remove newlines inside empty brackets with optional whitespace
    var jsonString = self

    // Parse JSON string into a Foundation object (dictionary or array)
    guard let jsonData = jsonString.data(using: .utf8),
          let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) else {
        return self // Return original string if parsing fails
    }
    
    // Convert the Foundation object back to JSON data with pretty-printing
    let prettyJSONData: Data
    do {
        prettyJSONData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
    } catch {
        return self // Return original string if prettification fails
    }
    
    // Convert JSON data to a string
    guard var prettyJSONString = String(data: prettyJSONData, encoding: .utf8) else {
        return self // Return original string if conversion fails
    }
    prettyJSONString = prettyJSONString.replacingOccurrences(of: "\\{\\s*\n+\\s*\\}", with: "{}", options: .regularExpression)
    prettyJSONString = prettyJSONString.replacingOccurrences(of: "\\[\n+\\]", with: "[]", options: .regularExpression)

    return prettyJSONString
}
  
}
  

extension StringProtocol {
    var data: Data { Data(utf8) }
    var base64Encoded: Data { data.base64EncodedData() }
    var base64Decoded: Data? { Data(base64Encoded: string) }
}

extension LosslessStringConvertible {
    var string: String { .init(self) }
}

extension Sequence where Element == UInt8 {
    var data: Data { .init(self) }
    var base64Decoded: Data? { Data(base64Encoded: data) }
    var string: String? { String(bytes: self, encoding: .utf8) }
}

