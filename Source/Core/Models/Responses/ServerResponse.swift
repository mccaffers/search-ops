// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
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

	/// For a failed status: "The cluster returned HTTP 403: <reason>", with the reason from the error body when it has one
	public var httpErrorMessage: String {
		let status = "The cluster returned HTTP \(httpStatus)"
		guard let body = data.flatMap({ String(data: $0, encoding: .utf8) }),
					let reason = ClusterUsers.errorReason(body), !reason.isEmpty else {
			return status + "."
		}
		return "\(status): \(reason)"
	}
}

