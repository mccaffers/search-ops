// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosSidebarAutoSuggest: View {
  @Binding var selection: macosSearchViewEnum
  @State private var timer: Timer?
  
  @Binding var searchText: String
  @Binding var fields: [SquashedFieldsArray]
  
  var filteredFields: [SquashedFieldsArray] {
    fields.filter { $0.squashedString.contains(searchText) }
  }
  
  var fixedRowHeight : CGFloat = 40
  
  @State var frameHeight : CGFloat = 0
  @Binding var lastValue : String
  
  var body: some View {
    VStack {
      VStack(alignment: .leading, spacing: 0) {
        ScrollView {
          ForEach(filteredFields) { field in
            Button {
              lastValue = field.squashedString
              searchText = lastValue
              selection = .None
            } label: {
              Text(field.squashedString)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .contentShape(Rectangle())
            }.buttonStyle(PlainButtonStyle())
          }
        }.frame(maxHeight: frameHeight)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color("Button"))
      .clipShape(RoundedRectangle(cornerRadius: 5))
//      .shadow(color: Color("Background"), radius: 5, x: 0, y: 0)
  
      
      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onChange(of: searchText) { newValue in
      frameHeight = CGFloat(filteredFields.count) * fixedRowHeight
      if frameHeight > 400 {
        frameHeight = 400
      }
    }
    .onAppear {
      frameHeight = CGFloat(filteredFields.count) * fixedRowHeight
      if frameHeight > 400 {
        frameHeight = 400
      }
      
      // Invalidate any existing timer before creating a new one
//      timer?.invalidate()
//      timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
//        self.selection = .None
//      }
    }
    .onDisappear {
      timer?.invalidate()
    }
  }
}
