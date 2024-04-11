// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

public class AuthBuilder {
        
    public static func ConvertCloudIDIntoHost(cloudID: String) -> (String, String) {
        
        let emptyResponse = ("", "")
        if(cloudID.count == 0){
            return emptyResponse
        }
        
        let id = cloudID.components(separatedBy: [":"])
        
        if(id.count <= 1){
            return emptyResponse
        }
        
        let myStrings = id[1].base64Decoded?.string?.components(separatedBy: ["$"])
        
        if let myStrings = myStrings {
            
            if myStrings.count <= 1 {
                return emptyResponse
            }
            
            let (host, port) = extractPortFromName(myStrings[0], Constants.DEFAULT_CLOUD_PORT) // (host, port) not used
            let (esID, _) = extractPortFromName(myStrings[1], Constants.DEFAULT_CLOUD_PORT)
            
            if !esID.isEmpty {
                return ("https://" + esID + "." + host, port)
            } else {
                return ("https://" + host, port)
            }
            
        } else {
            return emptyResponse
        }
    }
    
    
    
    public static func extractPortFromName(_ word: String, _ defaultPort: String) -> (String, String) {
        
        let idx = word.components(separatedBy: [":"])
        
        if idx.count > 1 && idx[1].isInt {
            
            // if the string is an int
            if let port = Int(idx[1]) {
                // if the int is more than zero
                if port > 0 {
                    return (idx[0], idx[1])
                }
            }
            
            // else drop into this return
            // returning a default port
            return (idx[0], defaultPort)
            
        }
        
        return (word, defaultPort)
    }
    
    public static func MakeBearer(username: String, password: String) -> String {
        let mergedCredentials = username + ":" + password
        return mergedCredentials.base64Encoded.string!
    }
}
