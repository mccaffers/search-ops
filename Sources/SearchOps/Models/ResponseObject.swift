// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

public enum ErrorResponseType : String, PersistableEnum {
    case critical, warn, information
}

@available(iOS 16.0, *)
public class ServerResponse {
	
	public init(data: Data? = nil, response: URLResponse? = nil, error: ResponseError? = nil) {
		self.data = data
		self.response = response
		self.error = error
		
	
	}
	
	public var data: Data? = nil
	public var response: URLResponse? = nil
	public var error: ResponseError? = nil
	public var parsed: String? = nil
	public var duration: ContinuousClock.Instant.Duration? = nil
	public var jsonReq: String? = nil
	public var httpStatus: Int = 0
	public var url : URL? = nil
	public var method : String? = nil
}

@available(iOS 15, *)
public class ResponseError {
	public let title: String
	public let message: String
	public let type : ErrorResponseType
	
	public init(title : String, message: String, type: ErrorResponseType) {
		self.message = message
		self.title = title
		self.type = type
	}
	
	public func ejectRealm() -> RealmResponseError {
		var realmObj = RealmResponseError()
		realmObj.message = self.message
		realmObj.title = self.title
		realmObj.type = self.type
		return realmObj
	}
}

