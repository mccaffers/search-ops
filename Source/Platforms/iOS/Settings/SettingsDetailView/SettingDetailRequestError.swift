// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SettingDetailRequestError: View {
	
	var errorTitle : String
	var errorMessage : String
	
    var body: some View {
			VStack {
				HStack {
					Text("HTTP Response")
						.foregroundColor(Color("TextColor"))
					
					Spacer()
					
					
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.horizontal, 15)
			}
			.padding(.vertical, 22)
			.background(Color("BackgroundAlt"))
			
			
			HStack (spacing:15) {
				Image(systemName: "exclamationmark.triangle")
					.font(.system(size: 22))
					.foregroundColor(.red)
				VStack (spacing:5){
					Text(errorTitle)
						.font(.system(size: 16, weight:.medium))
						.frame(maxWidth: .infinity, alignment:.leading)
					Text(errorMessage)
						.frame(maxWidth: .infinity, alignment:.leading)
				}
				.frame(maxWidth: .infinity, alignment:.leading)
			}
				.padding(.horizontal, 20)
				.padding(.top, 10)
    }
}

