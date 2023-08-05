//
//  File.swift
//  
//
//  Created by Ryan McCaffery on 30/06/2023.
//

import Foundation
import SwiftyJSON

// Functions to build the request

@available(iOS 16.0.0, *)
public class Indicies {
    
	public static func listIndexes(serverDetails: HostDetails) async -> ServerResponse {
		
		let clock = ContinuousClock()
		var response = ServerResponse()
		
		// only measuring the request
		let timeTaken = await clock.measure {
			
			response = await Request().invoke(serverDetails: serverDetails, endpoint: "/_aliases?pretty=true")
			
			if let data = response.data {
				response.parsed = String(bytes: data, encoding: String.Encoding.utf8) ?? "";
			}
			
		}
		
		response.duration = timeTaken
		
		await Logger.event(response: response,
													host: serverDetails)
		
		return response
		
	}
	
    public static func indexStats(serverDetails: HostDetails, index: String) async -> String {
			
        var endpoint = "/_stats"
        if index != "" {
            endpoint = "/" + index + "/_stats"
        }
        
        let response = await Request().invoke(serverDetails: serverDetails, endpoint: endpoint)
        
        if let data = response.data {
//            let data = response.Data
            return String(bytes: data, encoding: String.Encoding.utf8) ?? "";
        } else {
            return ""
        }
    }
}
