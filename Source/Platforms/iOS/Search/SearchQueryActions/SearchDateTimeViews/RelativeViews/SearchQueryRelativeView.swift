// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import Combine

struct SearchQueryRelativeView: View {

    @State var timeValue: String = ""
    @State var showQuickButtons : Bool = true

	@State var localRelativeRangeObject : RelativeRangeFilter = RelativeRangeFilter()
	@EnvironmentObject var filterObject : FilterObject
	
    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                
							SearchQueryDateView(localRelativeRangeObject : $localRelativeRangeObject)
                    .padding(.bottom, 5)
                
							VStack(spacing:5) {
								VStack(alignment: .leading) {
									Text("Custom Range")
										.foregroundColor(Color("TextSecondary"))
										.font(.system(size:14))
										.frame(maxWidth: .infinity, alignment:.leading)
									
								}
								.padding(.leading, 15)
								
								
								SearchQueryRelativeCustomInputView(localRelativeRangeObject : $localRelativeRangeObject)
									.padding(.bottom, 5)
								
								
							}
                Spacer()
                
            }

            
        }.scrollContentBackground(.hidden)
				.onAppear {
					if let relativeRange = filterObject.relativeRange {
						localRelativeRangeObject = relativeRange
					}
				}
            
    }
}

