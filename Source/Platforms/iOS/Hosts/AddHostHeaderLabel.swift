// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct AddHostHeaderLabel: View {
	var title : String
    var body: some View {
			VStack(alignment: .leading) {
				Text(title)
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(.leading, 20)

    }
}
