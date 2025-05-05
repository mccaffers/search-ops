// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)

struct SearchQueryDateSheetTimePicker: View {
  
  @Binding var selectedIndex : String
  
  @EnvironmentObject var orientation : Orientation
  @EnvironmentObject var filteredObject: FilterObject
  
  @State var selection : SearchDateTimePicker = SearchDateTimePicker.Unknown
  
  var body: some View {
    
 
      VStack(
        alignment: .leading,
        spacing: 0
      ) {
        
        VStack (spacing:0) {
          SearchQueryPicker(selection: $selection)
        }
        .background(Color("BackgroundAlt"))
        
        if selection == SearchDateTimePicker.Absolute {
          SearchQueryAbsoluteView()
          
        } else if selection == SearchDateTimePicker.Relative {
          SearchQueryRelativeView()
          
        }
      
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("Background"))
    .navigationTitle("Date Range")
#if os(iOS)
    .navigationBarTitleDisplayMode(.large)
#endif
    .onAppear {
      if filteredObject.absoluteRange != nil {
        selection = .Absolute
      } else {
        selection = .Relative
      }
    }
  }
}
#endif
