//
//  File.swift
//  
//
//  Created by Ryan McCaffery on 30/06/2023.
//

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
            print(input)
            print("Failed to load: \(error.localizedDescription)")
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
    
    
}
