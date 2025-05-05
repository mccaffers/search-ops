// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct HostsNavigationStackView: View {
	var body: some View {
		
		NavigationStack {
			VStack {
				ServicesHome()
				Spacer()
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(Color("Background"))
		}
	}
}
#endif
