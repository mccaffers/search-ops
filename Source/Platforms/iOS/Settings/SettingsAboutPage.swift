// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SettingsAboutPage: View {
	
	var body: some View {
		VStack {
			Text("By Ryan")
			Text("Thanks!")
			Text("mccaffers.com")
		}
		.frame(maxWidth: .infinity)
		.frame(maxHeight: .infinity)
		.background(Color("Background"))
		.navigationTitle("About")
		
		
	}
}
