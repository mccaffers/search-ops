// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SheetQueryCustom: View {
  
  @State var value = ""
  @FocusState private var focusedField: FocusField?
  
  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 10
    ) {
      
      TextEditor(text:$value)
        .focused($focusedField, equals: .field)
        .scrollContentBackground(.hidden)
        .background(.white)
        .accentColor(.black)
        .foregroundColor(.black)
        .border(.gray)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
      
    }
    .padding(.top,5)
  }
}
