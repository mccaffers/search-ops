// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13.0, *)
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

