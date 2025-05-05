// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHomeDateValuesAbsolute: View {
  
  @ObservedObject var filterObject : FilterObject
  @Binding var selection: macosSearchViewEnum
  @Binding var relativeCustomdatePeriod : SearchDateTimePeriods?
  
  func formattedDate(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .medium
    return formatter.string(from: date)
  }
  
  func hasBeenDefined(selected: Bool = false) -> Bool {
    if filterObject.relativeRange != nil ||
        filterObject.absoluteRange != nil {
      // This means the calendar view is in sight
      if selected {
        return false
      }
      return true
    }
    return false
  }
  
  var body: some View {
    VStack (alignment: .leading, spacing:5) {
      HStack(alignment:.top) {
        VStack(alignment:.leading, spacing:5) {
          Text("Date Range")
            .font(.subheadline)
            .foregroundStyle(Color("TextSecondary"))
          
          HStack {
            Button {
              selection = .NewSearchDatePickerFrom
            } label: {
              
              if let relativeRange = filterObject.relativeRange {
                Text(relativeRange.GeneratePrettyTimeString())
                  .padding(10)
                  .background(Color("Background"))
                  .clipShape(.rect(cornerRadius: 5))
              } else if let absoluteRange = filterObject.absoluteRange {
                Text(absoluteRange.from.formatted())
                  .padding(10)
                  .background(Color("Background"))
                  .clipShape(.rect(cornerRadius: 5))
              } else {
                HStack {
                  Image(systemName: "calendar")
                  Text("From")
                }
                .padding(10)
                .background(Color("Button"))
                .clipShape(.rect(cornerRadius: 5))
              }
              
              
            }.buttonStyle(PlainButtonStyle())
            
            Image(systemName: "chevron.right")
            
            Button {
              if filterObject.absoluteRange == nil {
                filterObject.absoluteRange = AbsoluteDateRangeObject(from: Date.now, to: Date.now)
                filterObject.relativeRange = nil
              }
              
              selection = .NewSearchDatePickerTo
            } label: {
              if let relativeRange = filterObject.relativeRange {
                Text("Now")
                  .padding(10)
                  .background(Color("Background"))
                  .clipShape(.rect(cornerRadius: 5))
              } else if let absoluteRange = filterObject.absoluteRange {
                Text(absoluteRange.to.formatted())
                  .padding(10)
                  .background(Color("Background"))
                  .clipShape(.rect(cornerRadius: 5))
              } else {
                HStack {
                  Image(systemName: "calendar")
                  Text("To")
                }
                .padding(10)
                .background(Color("Button"))
                .clipShape(.rect(cornerRadius: 5))
              }
              
              
            }.buttonStyle(PlainButtonStyle())
          }
          
        }
        
        macosSearchHomeDateValueViews(selection:$selection,
                                      filterObject: filterObject,
                                      relativeCustomdatePeriod:$relativeCustomdatePeriod)
        
      }
    }
  }
}
