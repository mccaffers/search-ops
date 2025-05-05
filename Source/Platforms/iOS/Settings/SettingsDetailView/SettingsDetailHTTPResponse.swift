// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SettingsDetailHTTPResponse: View {
	
	var status = 0
	var duration = ""
	var error: RealmResponseError?
	
	var body: some View {
		VStack {
			VStack {
				HStack {
					Text("HTTP Response")
						.foregroundColor(Color("TextColor"))
						.padding(.vertical, 10)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.horizontal, 15)
			}
			.padding(.vertical, 10)
			.background(Color("BackgroundAlt"))
			
			VStack(spacing:10) {
				HStack(spacing:10) {
					Text("Status")
						.frame(width: 120, alignment: .trailing)
					
					if let 	error = error,
						 error.type == .critical {
						Text(error.title)
							.foregroundColor(.red)
							.frame(maxWidth: .infinity, alignment: .leading)
					} else {
						Text(status.string)
							.foregroundColor(HTTPStatusColors.getStatusColor(input: status))
							.frame(maxWidth: .infinity, alignment: .leading)
					}
				}
				
				HStack(spacing:10) {
					Text("Time")
						.frame(width: 120, alignment: .trailing)
					Text(duration)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
				
				if let 	error = error,
					 error.type == .critical {
					HStack(spacing:10) {
						Text("Error")
							.frame(width: 120, alignment: .trailing)
						Text(error.message)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					
				}
				
			}
		}
	}
}
