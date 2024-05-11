// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

/// A utility class responsible for authentication and authorization operations within the SearchOps iOS Application.
public class AuthBuilder {
  
  /// Converts a cloud ID into a host and port.
  /// - Parameter cloudID: A string representing the cloud ID, expected to be formatted and base64 encoded.
  /// - Returns: A tuple containing the host URL as a string and the port as a string.
  ///            Returns empty strings for both if the input is invalid or not as expected.
  public static func ConvertCloudIDIntoHost(cloudID: String) -> (String, String) {
    let emptyResponse = ("", "")
    
    // Return empty if the cloudID is empty
    if(cloudID.count == 0){
      return emptyResponse
    }
    
    // Split the cloudID by colon
    let id = cloudID.components(separatedBy: [":"])
    
    // Return empty if there is no colon separator
    if(id.count <= 1){
      return emptyResponse
    }
    
    // Attempt to decode the second part of the split string and split by dollar sign
    let idComponents = id[1].base64Decoded?.string?.components(separatedBy: ["$"])
    
    // Check if the decoded string is valid and split into components
    if let idComponents = idComponents {
      // Return empty if the split result has less than 2 parts
      if idComponents.count <= 1 {
        return emptyResponse
      }
      
      // Extract host and port from the first part (not used further in this function)
      let (host, port) = extractPortFromName(idComponents[0], Constants.defaultPort)
      // Extract Elasticsearch ID and port from the second part
      let (esID, _) = extractPortFromName(idComponents[1], Constants.defaultPort)
      
      // Formulate the host URL and return it with the port
      if !esID.isEmpty {
        return ("https://" + esID + "." + host, port)
      } else {
        return ("https://" + host, port)
      }
    } else {
      // Return empty if decoding fails
      return emptyResponse
    }
  }
  
  /// Extracts the port number from a string that may contain a host and a port separated by a colon.
  /// - Parameters:
  ///   - word: A string potentially containing a host and port (e.g., "example.com:80").
  ///   - defaultPort: The default port to return if no valid port number is found in the input string.
  /// - Returns: A tuple where the first element is the host and the second is the port.
  public static func extractPortFromName(_ word: String, _ defaultPort: String) -> (String, String) {
    let idx = word.components(separatedBy: [":"])
    
    // Check if there are two components and the second is an integer
    if idx.count > 1 && idx[1].isInt {
      if let port = Int(idx[1]), port > 0 {
        // Return the first part as host and the second as port if the port is a positive integer
        return (idx[0], idx[1])
      }
    }
    
    // Return the input word as host and the default port if no valid port is found
    return (idx[0], defaultPort)
  }
  
  /// Creates a Base64-encoded bearer token from a username and password.
  /// - Parameters:
  ///   - username: The user's username.
  ///   - password: The user's password.
  /// - Returns: A Base64-encoded string that combines the username and password.
  public static func MakeBearer(username: String, password: String) -> String {
    let mergedCredentials = username + ":" + password
    // Encode the merged credentials and return
    return mergedCredentials.base64Encoded.string!
  }
}
