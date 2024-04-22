// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

import Foundation

/// The `Logger` class is responsible for logging server response details for debugging and analytics purposes.
/// Available on macOS 13.0+ and iOS 16.0+.
@available(macOS 13.0, *)
@available(iOS 16.0, *)
public class Logger {
  
    /// Logs a server event based on various parameters detailing the response and request environment.
    /// - Parameters:
    ///   - response: The server's response containing details like duration, status, and any errors.
    ///   - index: An optional identifier for indexing logs.
    ///   - host: Details about the server host, including name and environment.
    ///   - filterObject: An optional object that filters logs based on specified criteria.
    ///   - page: The page number of the logged event, generally used for paginated results.
    ///   - hitCount: The number of hits or interactions recorded for this event.
    @MainActor
    public static func event(response: ServerResponse,
                             index: String = "",
                             host: HostDetails,
                             filterObject: FilterObject? = nil,
                             page: Int = 0,
                             hitCount: Int = 0) {
        
        let logEvent = LogEvent()
        
        // Format and assign the duration of the server response, if available.
        if let duration = response.duration {
            logEvent.duration = duration.formatted(.units(allowed: [.milliseconds]))
        }
        
        // Extract and handle error information from the response.
        logEvent.error = response.error?.ejectRealm()
        logEvent.jsonRes = response.parsed ?? ""
        logEvent.httpStatus = response.httpStatus
        logEvent.method = response.method ?? ""
        logEvent.index = index
        logEvent.host = LogHostDetails()
        logEvent.host?.name = host.name
        logEvent.host?.env = host.env
        
        // Setup host details based on the URL from the response.
        logEvent.host?.host = HostURL()
        if let url = URL(string: response.url?.absoluteString ?? "") {
            logEvent.host?.host?.scheme = url.scheme == "https" ? .HTTPS : .HTTP
            logEvent.host?.host?.url = url.host ?? ""
            logEvent.host?.host?.path = url.pathComponents.joined(separator: "/")
            
            // Remove the leading "/" from path if present.
            if let path = logEvent.host?.host?.path, path.hasPrefix("/") {
                logEvent.host?.host?.path.remove(at: path.startIndex)
            }
        }
        
        // Convert and assign the JSON request to a string format.
        if let jsonReq = JSON(response.jsonReq ?? "").rawString() {
            logEvent.jsonReq = jsonReq
        }
        
        // Handle the filtering object for logs if provided.
        if let filterObject = filterObject {
            logEvent.filter = LogFilter()
            if let dateField = filterObject.dateField {
                logEvent.filter?.dateField = RealmSquasedFieldsArray(squasedField: dateField)
            }
            if let queryObj = filterObject.query {
                logEvent.filter?.query = queryObj.eject()
            }
            if let relativeObj = filterObject.relativeRange {
                logEvent.filter?.relativeRange = relativeObj.ejectRealmObject()
            }
        }
        
        // Add the newly created log event to the data manager for storage or further processing.
        LogDataManager().addNew(item: logEvent)
    }
}
