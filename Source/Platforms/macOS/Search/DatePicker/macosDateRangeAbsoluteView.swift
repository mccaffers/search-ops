// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosDateRangeAbsoluteView: View {
  @ObservedObject var filterObject: FilterObject

  @State var absoluteCalendar: macosAbsoluteCalendarEnum = .FromActive

  @State var selectedDateFrom: Date = Date()
  @State var selectedDateTo: Date = Date()

  @Binding var view: macosDatePickerEnum
  
  @State var fromNow : Bool = false
  @State var toNow : Bool = false
  @Binding var topBarDateButtonRefresh : UUID
  
  var body: some View {
    VStack(spacing:0) {
      // From
      macosDateRangePicker(
        absoluteCalendar: $absoluteCalendar,
        selectedDate: $selectedDateFrom,
        filterObject: filterObject,
        nowField: $fromNow,
        activeCalendar: .FromActive,
        fieldName: "From"
      )
      .onAppear {
        if let absoluteRange = filterObject.absoluteRange {
          selectedDateFrom = absoluteRange.from
          fromNow = absoluteRange.fromNow
        }
      }
      .onChange(of: selectedDateFrom) { newValue in
        if filterObject.absoluteRange == nil {
          filterObject.absoluteRange = AbsoluteDateRangeObject(from: newValue, to: Date.now)
        } else {
          filterObject.absoluteRange?.from = newValue
        }
        topBarDateButtonRefresh = UUID()
      }
      .onChange(of: fromNow) { newValue in
        filterObject.absoluteRange?.fromNow = newValue
        topBarDateButtonRefresh = UUID()
      }
      
      // To
      macosDateRangePicker(
        absoluteCalendar: $absoluteCalendar,
        selectedDate: $selectedDateTo,
        filterObject: filterObject,
        nowField: $toNow,
        activeCalendar: .ToActive,
        fieldName: "To"
      )
      .padding(.bottom, 10)
  
      .onAppear {
        if let absoluteRange = filterObject.absoluteRange {
          selectedDateTo = absoluteRange.to
          toNow = absoluteRange.toNow
        }
      }
      .onChange(of: selectedDateTo) { newValue in
        if filterObject.absoluteRange == nil {
          filterObject.absoluteRange = AbsoluteDateRangeObject(from: Date.now, to: newValue)
        } else {
          filterObject.absoluteRange?.to = newValue
        }
        topBarDateButtonRefresh = UUID()
      }
      .onChange(of: toNow) { newValue in
        filterObject.absoluteRange?.toNow = newValue
        topBarDateButtonRefresh = UUID()
      }
    }
    
    .onChange(of: selectedDateTo) { newValue in
      filterObject.absoluteRange?.to = newValue
    }
  }
}

struct macosDateRangePicker: View {
  @Binding var absoluteCalendar: macosAbsoluteCalendarEnum
  @Binding var selectedDate: Date
  var filterObject: FilterObject
  @Binding var nowField : Bool
  var activeCalendar: macosAbsoluteCalendarEnum
  
  var fieldName : String

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(spacing: 3) {
          Button {
            if absoluteCalendar == activeCalendar {
              absoluteCalendar = .None
            } else {
              absoluteCalendar = activeCalendar
              nowField = false
             
            }
          } label: {
            VStack {
              Text(fieldName)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
              Group {
                if nowField {
                  Text("Now")
                } else {
                  Text(selectedDate.formatted())
                }
              }
              .font(.system(size: 14))
              .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 10)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
        }
        Spacer()
        
        // only show the now button for the to fields, makes no sense
        // to show from Now for the from field
        
        if activeCalendar == .ToActive {
          VStack {
            Button {
              nowField = true
              absoluteCalendar = .None
            } label: {
              Text("Now")
                .padding(10)
                .background(Color("Background"))
                .clipShape(.rect(cornerRadius: 5))
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
      }
      .padding(.trailing, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color("Button"))
      .contentShape(Rectangle())
      .clipShape(.rect(
        topLeadingRadius: 5,
        bottomLeadingRadius: absoluteCalendar == activeCalendar ? 0 : 5,
        bottomTrailingRadius: absoluteCalendar == activeCalendar ? 0 : 5,
        topTrailingRadius: 5
      ))

      if absoluteCalendar == activeCalendar {
        macosAbsoluteCalendarWrapperView(selectedDate: $selectedDate)
      }
    }
    .padding(.horizontal, 10)
    .padding(.top, 10)
  }
}
