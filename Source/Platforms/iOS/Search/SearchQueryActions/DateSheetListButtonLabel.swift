// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct DateSheetListButtonLabel: View {
	
	func highlightIfActive(input: SquashedFieldsArray) -> Color {
		if let field = activeField,
			 input.squashedString == field.squashedString,
			 input.fieldParts == field.fieldParts {
			return Color("ButtonHighlighted")
		} else {
			return Color("Button")
		}
	}

	var activeField : SquashedFieldsArray?
	var item: SquashedFieldsArray
	var selectedIndex: String?
	var fieldCount : Int
	
    var body: some View {
			VStack(
				alignment: .leading,
				spacing: 5
			) {
				
				if selectedIndex != nil {
					Text(item.index)
						.font(.system(size: 13))
						.padding(.horizontal, 10)
						.multilineTextAlignment(.leading)
				}
				
				HStack {
					Text(item.squashedString)
						.font(.system(size: 16, weight: .regular))
						.padding(.horizontal, 10)
						.multilineTextAlignment(.leading)
					Spacer()
					Text(item.type)
						.font(.system(size: 16, weight: .regular))
						.padding(.horizontal, 10)
						.multilineTextAlignment(.leading)
				}
				
			}
			.frame(maxWidth: .infinity, alignment:.leading)
			.padding(.vertical, fieldCount > 10 ? 10 : 20)
			.foregroundColor(.white)
			.background(highlightIfActive(input:item))
			.cornerRadius(5)
			.padding(.horizontal, 10)
    }
}

