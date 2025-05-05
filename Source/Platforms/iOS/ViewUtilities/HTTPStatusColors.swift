// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct HTTPStatusColors {
	static func getStatusColor(input: Int) -> Color {
		if input >= 200 && input < 300 {
			return .green
		} else if input >= 300 && input < 400 {
			return .orange
		} else {
			return .red
		}
	}
}

