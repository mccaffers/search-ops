// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosDatePicker: View {
  @Binding var selectedIndex: String
  
  var body: some View {
    VStack {
//      macosDatePickerView(selectedIndex: $selectedIndex)
    }
    .frame(maxWidth: .infinity)
    .background(Color("Background"))
    .clipShape(RoundedRectangle(cornerRadius: 5))

  }
}

