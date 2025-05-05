// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchRangeSheetHeader: View {
  var body: some View {
    
    VStack (spacing:0) {
      
      RoundedRectangle(cornerRadius: 5)
        .fill(.clear)
        .frame(height:10)
        .frame(width:1)
      
      RoundedRectangle(cornerRadius: 5)
        .fill(Color("SheetTopIndicator"))
        .frame(height:3)
        .frame(width:25)
      
      HStack(
        alignment: .center,
        spacing: 2
      ) {
        
        Text("Range Filter")
          .font(.system(size: 25, weight: .light))
          .padding(.leading, 20)
        
        Spacer()
        
        Button {
          
        } label: {
          
          VStack (spacing:0) {
            HStack {
              Text("Clear")
            }
            .foregroundColor(Color("TextColor"))
          }
          .padding(10)
          .background(Color("WarnButton"))
          .cornerRadius(5)
        }
        
      }
      .frame(height: 55)
      .padding(.top, 7)
      .padding(.bottom, 5)
      .padding(.trailing, 15)
      
    }
  }
}
