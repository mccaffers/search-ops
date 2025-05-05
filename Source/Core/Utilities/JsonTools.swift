// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

public class JsonTools {
  
  public static func serialiseJson(_ input: String) -> [String: Any]? {
    if input.count == 0 {
      return nil
    }
    
    do {
      let data = Data(input.utf8)
      // make sure this JSON is in the format we expect
      if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        // try to read out a string array
        return json
      }
    } catch let error as NSError {
      SystemLogger().message("Failed to load: \(error.localizedDescription)")
    }
    return nil
  }
  
  public static func swiftySerialiser(_ input: String) -> JSON? {
    if input.count == 0 {
      return nil
    }
    
    let json = JSON(input)
    
    return json
  }
  
  public static func tidyUpString(_ input: String) -> String {
    return input.replacingOccurrences(of: "\n", with: "")
//    return (input as NSString).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
  }

  
  public static func deserialiseJSON(input: JSON) -> String {
    
    if let string = input.rawString([.encoding : String.Encoding.utf8])  {
      //Do something you want
      return string
    }
    return ""
  
  }
  
}
