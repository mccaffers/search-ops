// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

// Defines functions related to ElasticSearch index operations for use within an iOS app,
// compatible with macOS 13.0 and iOS 16.0 or later.
@available(macOS 13.0, *)
@available(iOS 16.0.0, *)
public class Indicies {
  
  /// Fetches a list of all indices from the specified ElasticSearch server.
  /// Allows specifying a custom endpoint to target different ElasticSearch functionalities.
  /// Default endpoint fetches aliases in a pretty JSON format.
  /// - Parameters:
  ///   - serverDetails: Contains the details about the server (e.g., credentials, URL).
  ///   - endpoint: The specific API endpoint to make the HTTP request to.
  /// - Returns: A `ServerResponse` containing the API response details, including the duration of the request.
  public static func listIndexes(serverDetails: HostDetails, endpoint: String = "/_aliases?pretty=true") async -> ServerResponse {
    
    let clock = ContinuousClock()  // Object for measuring time taken for a code execution block.
    var response = ServerResponse()  // Struct to hold the response details.
    
    // Measures the time taken to perform the HTTP request.
    let timeTaken = await clock.measure {
      
      // Perform the HTTP request and store the result in `response`.
      response = await Request().invoke(serverDetails: serverDetails, endpoint: endpoint)
      
      // If data is present in the response, convert it to a UTF-8 string.
      if let data = response.data {
        response.parsed = String(bytes: data, encoding: String.Encoding.utf8) ?? "";
      }
    }
    
    // Set the measured duration in the response object.
    response.duration = timeTaken
    
    // Log the response for debugging or audit purposes.
    await Logger.event(response: response,
                       host: serverDetails)
    
    return response
    
  }
  
  /// Retrieves statistics for a specific index or all indices if no index is specified.
  /// - Parameters:
  ///   - serverDetails: Contains the server details needed for the request.
  ///   - index: The specific index to retrieve stats for, defaults to all indices if empty.
  /// - Returns: A string representation of the stats data in UTF-8 format, or an empty string if no data.
  public static func indexStats(serverDetails: HostDetails, index: String) async -> String {
    
    // Default endpoint for getting stats of all indices.
    var endpoint = "/_stats"
    // Modify the endpoint if a specific index is provided.
    if index != "" {
      endpoint = "/" + index + "/_stats"
    }
    
    // Perform the HTTP request.
    let response = await Request().invoke(serverDetails: serverDetails, endpoint: endpoint)
    
    // Convert the response data to a UTF-8 string if present, otherwise return an empty string.
    if let data = response.data {
      return String(bytes: data, encoding: String.Encoding.utf8) ?? "";
    } else {
      return ""
    }
  }
}
