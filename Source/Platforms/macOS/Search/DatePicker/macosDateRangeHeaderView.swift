// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosDateRangeHeaderView: View {
  @EnvironmentObject var filterObject: FilterObject
  @State var onHoverDateField = false
  
  @Binding var view : macosDatePickerEnum
  @Binding var showingMappedDateFields : Bool
  
    var body: some View {
      HStack(alignment:.bottom) {
        Button {
          showingMappedDateFields.toggle()
        } label: {
          VStack(alignment:.leading) {
            Text("Date Field")
              .font(.footnote)
              .bold()
            Text(filterObject.dateField?.squashedString ?? "")
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(onHoverDateField ?  Color("ButtonHighlighted") : Color("Button"))
          .clipShape(.rect(cornerRadius: 5))
          .padding(.vertical, 5)
        }
        .onHover { hover in
          onHoverDateField = hover
        }
        .buttonStyle(PlainButtonStyle())

       
        Spacer()
        if !showingMappedDateFields {
          DatePickerHeaderView(view: $view)
        }
        
      }
      .padding(.leading, 10)
      .frame(maxWidth: .infinity)
      .background(Color("Button"))
    }
}

