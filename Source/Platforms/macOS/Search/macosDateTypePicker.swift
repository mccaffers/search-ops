// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosDateTypePicker: View {
  @Binding var selectedIndex: String
  var fields : [SquashedFieldsArray]
  @State var loadingFields : String = ""
  @Binding var updatedFieldsNotification : UUID
  
  var body: some View {
    VStack {
      macosMainSheetDateCardView(selectedIndex: $selectedIndex,
                            fields: fields,
                            loading: $loadingFields)
      .id(updatedFieldsNotification)
      
    }
    .frame(maxWidth: .infinity)
    .background(Color("Background"))
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .stroke(Color("LabelBackgroundFocus"), lineWidth: 2)
    )
  }
}
