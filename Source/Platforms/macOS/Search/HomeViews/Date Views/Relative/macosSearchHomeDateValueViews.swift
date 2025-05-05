// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHomeDateValueViews: View {
  
  @Binding var selection: macosSearchViewEnum
  @ObservedObject var filterObject : FilterObject
  
  @State var showingCustom : Bool = false
  @State var hoveringActiveButton = false
  
  @Binding var relativeCustomdatePeriod : SearchDateTimePeriods?

  var body: some View {
    VStack(alignment:.leading, spacing:5) {
      Text("Relative Range")
        .font(.subheadline)
        .foregroundStyle(Color("TextSecondary"))

      if let relativeRange = filterObject.relativeRange {
        HStack {
          Button {
            filterObject.relativeRange = nil
          } label: {
            Text(relativeRange.GeneratePrettyTimeString())
              .padding(10)
              .background(Color("Background"))
              .clipShape(.rect(cornerRadius: 5))
          }.buttonStyle(PlainButtonStyle())
            .onHover { hover in
              hoveringActiveButton = hover
            }
            if hoveringActiveButton {
              Image(systemName: "xmark.circle")
                .bold()
                .padding(.leading, -15)
                .padding(.top, -25)
            }
          Spacer()
        }
      } else if !showingCustom {
        WrappingHStack(horizontalSpacing: 5) {
          macosSearchHomeRelativeButtons(filterObject:filterObject,
                                         selection: $selection,
                                         config: DatePickerButtonConfig(title: "Last 5 Minutes", value: 5.0, period: .Minutes))
          
          macosSearchHomeRelativeButtons(filterObject:filterObject,
                                         selection: $selection,
                                         config: DatePickerButtonConfig(title: "Last Hour", value: 1.0, period: .Hours))
          
          macosSearchHomeRelativeButtons(filterObject:filterObject,
                                         selection: $selection,
                                         config: DatePickerButtonConfig(title: "Last Day", value: 1.0, period: .Days))
          
          macosSearchHomeRelativeButtons(filterObject:filterObject,
                                         selection: $selection,
                                         config: DatePickerButtonConfig(title: "Last Week", value: 1.0, period: .Weeks))
          
          macosSearchHomeRelativeButtons(filterObject:filterObject,
                                         selection: $selection,
                                         config: DatePickerButtonConfig(title: "Last Month", value: 1.0, period: .Months))
          
          macosSearchHomeRelativeButtons(filterObject:filterObject,
                                         selection: $selection,
                                         config: DatePickerButtonConfig(title: "Last 6 Months", value: 6.0, period: .Months))
          
          macosSearchHomeRelativeButtons(filterObject:filterObject,
                                         selection: $selection,
                                         config: DatePickerButtonConfig(title: "Last Year", value: 1.0, period: .Years))
          
          Button {
            showingCustom.toggle()
            filterObject.absoluteRange = nil
            filterObject.relativeRange = nil
          } label: {
            Text("Custom")
              .padding(10)
              .background(filterObject.absoluteRange == nil ? Color("Button") : Color("Background"))
              .clipShape(.rect(cornerRadius: 5))
          }
          .buttonStyle(PlainButtonStyle())
          
        }.frame(maxWidth: .infinity)
      } else {
        macosSearchHomeRelativeCustomView(selection: $selection,
                                          relativeCustomdatePeriod: $relativeCustomdatePeriod,
                                          localFilterObject: filterObject,
                                          showingCustom: $showingCustom)
      }
      
    }
  }
}


//struct macosSearchHomeDateValueViews_Previews: PreviewProvider {
//  
//  @StateObject static var filterObject = FilterObject()
//  
//  static var previews: some View {
//    macosSearchHomeDateValueViews(selection: .constant(.None),
//                                  filterObject: filterObject,
//                                  view: .constant(.Relative))
//  }
//}
