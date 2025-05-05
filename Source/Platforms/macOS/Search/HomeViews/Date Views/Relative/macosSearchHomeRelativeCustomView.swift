// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHomeRelativeCustomView: View {
  
  @State var relativeText = "60"
  @Binding var selection: macosSearchViewEnum
  @Binding var relativeCustomdatePeriod : SearchDateTimePeriods?
  @ObservedObject var localFilterObject : FilterObject
  @Binding var showingCustom : Bool
  
    var body: some View {
      HStack (spacing:5){
        
        TextField("", text: $relativeText)
          .textFieldStyle(PlainTextFieldStyle())
          .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
          .frame(height: 36)
          .background(Color("Button"))
          .clipShape(.rect(cornerRadius: 5))
          .overlay(
            RoundedRectangle(cornerRadius: 5)
              .stroke(Color("BackgroundAlt"), lineWidth: 1)
          )
          .frame(maxWidth: 150)
        Button {
          selection = .NewSearchRelativeCustomValues
        } label: {
          HStack {
            if let relativeCustomdatePeriod = relativeCustomdatePeriod {
              Text(relativeCustomdatePeriod.rawValue)
            }
            Image(systemName: "chevron.up.chevron.down")
          }
          .padding(10)
          .background(Color("Button"))
          .cornerRadius(5)
        }
        .buttonStyle(PlainButtonStyle())
        
        Button {
          if let relativeCustomdatePeriod = relativeCustomdatePeriod {
            localFilterObject.relativeRange = RelativeRangeFilter(period: relativeCustomdatePeriod,
                                                                  value: Double(relativeText) ?? 0)
          }
        } label: {
          Text("Set")
            .padding(10)
            .background(Color("PositiveButton"))
            .clipShape(.rect(cornerRadius: 5))
        }.buttonStyle(PlainButtonStyle())
        
        Button {
          showingCustom = false
        } label: {
          Text("Cancel")
            .padding(10)
            .background(Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
        }.buttonStyle(PlainButtonStyle())
        
        Spacer()
      }
    
    }
}
