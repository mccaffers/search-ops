// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHomeRelativeButtons: View {
    @ObservedObject var filterObject : FilterObject
      @Binding var selection: macosSearchViewEnum
      var config: DatePickerButtonConfig
      var extraFunction : () -> () = {}
  
      var body: some View {
          Button {
              updateDateObject(input: config.value, period: config.period)
              selection = .None
            extraFunction()
          } label: {
              Text(config.title)
                  .padding(10)
                  .background(filterObject.absoluteRange == nil ? Color("Button") : Color("Background"))
                  .cornerRadius(5)
          }
          .buttonStyle(PlainButtonStyle())
      }

      func updateDateObject(input: Double, period: SearchDateTimePeriods) {
          if filterObject.relativeRange == nil {
              filterObject.relativeRange = RelativeRangeFilter()
          }
        filterObject.relativeRange = RelativeRangeFilter(period: period, value: input)
        filterObject.absoluteRange = nil
          
      }

      func existingTime(input: Double, period: SearchDateTimePeriods) -> Bool {
          if let dateObj = filterObject.relativeRange {
//            print(dateObj.value, dateObj.period)
//            print(input, period)
              return dateObj.value == input && dateObj.period == period
          }
          return false
      }
  }
