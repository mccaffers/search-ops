// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

@available(iOS 16.0, *)
public class Logger {
	
	@MainActor
	public static func event(response : ServerResponse,
													 index : String = "",
													 host : HostDetails,
													 filterObject: FilterObject? = nil,
													 page : Int = 0,
													 hitCount : Int = 0) {
		
		let logEvent = LogEvent()
		
		if let duration = response.duration {
			logEvent.duration = duration.formatted(.units(allowed: [.milliseconds]))
		}
		
		logEvent.error = response.error?.ejectRealm()
		logEvent.jsonRes = response.parsed ?? ""
		logEvent.httpStatus = response.httpStatus
		logEvent.method = response.method ?? ""
		logEvent.index = index
		logEvent.host = LogHostDetails()
		logEvent.host?.name = host.name
		logEvent.host?.env = host.env
		logEvent.host?.host = HostURL()
		logEvent.page = page
		logEvent.hitCount = hitCount
		
		if let url = URL(string:response.url?.absoluteString ?? "") {
			if url.scheme == "https" {
				logEvent.host?.host?.scheme = .HTTPS
			} else if url.scheme == "http" {
				logEvent.host?.host?.scheme = .HTTP
			}
			
			
			logEvent.host?.host?.url = url.host ?? ""
			logEvent.host?.host?.path = url.pathComponents.joined(separator:"/")
			if let path = logEvent.host?.host?.path,
				 path.hasPrefix("/") {
				logEvent.host?.host?.path.remove(at: path.startIndex)
			}
			
		}
		
		if let jsonReq = JSON(response.jsonReq ?? "").rawString() {
			logEvent.jsonReq = jsonReq
		}
		
		
		if let filterObject = filterObject {
			
			logEvent.filter = LogFilter()
			if let dateField  = filterObject.dateField {
				logEvent.filter?.dateField = RealmSquasedFieldsArray(squasedField: dateField)
			}
			
			if let queryObj = filterObject.query {
				logEvent.filter?.query = queryObj.eject()
			}
			
			if let relativeObj = filterObject.relativeRange {
				logEvent.filter?.relativeRange = relativeObj.ejectRealmObject()
			}
		}
		
		// Response Objects
		LogDataManager().addNew(item: logEvent)
		
	}
	
}
