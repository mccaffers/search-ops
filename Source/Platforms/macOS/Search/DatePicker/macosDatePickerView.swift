// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

enum macosDatePickerEnum {
  case Relative
  case Absolute
  case Loading
}

enum macosAbsoluteCalendarEnum {
  case ToActive
  case FromActive
  case None
}

struct macosDatePickerView: View {
  @Binding var selectedIndex: String
  @EnvironmentObject var filterObject: FilterObject
  @Binding var selection: macosSearchViewEnum
  
  @State var view : macosDatePickerEnum = .Loading
  
  @Binding var topBarDateButtonRefresh : UUID
  
  @State var showingMappedDateFields = false
  
  @Binding var fields : [SquashedFieldsArray]
  @State var showingCustomValues = false

  
  var body: some View {
    
    VStack(alignment: .leading, spacing: 0) {
      
      // not showing fields, so show the relative/absolute buttons at the top
      if !showingMappedDateFields {
        macosDateRangeHeaderView(view:$view,
                                 showingMappedDateFields:$showingMappedDateFields)
      }
      
      // showing fields to select
      if showingMappedDateFields {
        macosDatePickerFieldsView(selection: $selection, 
                                  fields: $fields,
                                  showingMappedDateFields: $showingMappedDateFields)
      } else {
        if view == .Relative {

          if !showingCustomValues {
            DatePickerButtonsView(selection: $selection, filterObject: filterObject)
              .padding(10)
          }
          
          macosDatePickerRelativeCustomView(showingCustomValues: $showingCustomValues,
                                            filterObject: filterObject,
                                            selection: $selection)
          .onAppear {
            
            
            if filterObject.relativeRange == nil {
              showingCustomValues = false
            } else if filterObject.relativeRange?.value == 5,
               filterObject.relativeRange?.period == .Minutes {
              showingCustomValues = false
            } else if filterObject.relativeRange?.value == 1 {
              let period = filterObject.relativeRange?.period
              if period == .Hours ||
                  period == .Days ||
                  period == .Weeks ||
                  period == .Months ||
                  period == .Years  {
                  showingCustomValues = false
              }
            } else {
              showingCustomValues = true
            }
            
          }
        } else {
          macosDateRangeAbsoluteView(filterObject: filterObject,
                                     view: $view,
                                     topBarDateButtonRefresh: $topBarDateButtonRefresh)
        }
        
//        macosDatePickerRefreshView()
      }
    }
    .onAppear {
      if filterObject.dateField == nil {
        showingMappedDateFields = true
      }
      if filterObject.absoluteRange != nil {
        view = .Absolute
      } else {
        view = .Relative
      }
    }
    .frame(maxWidth: .infinity)
    .background(Color("Background"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
 
  }
}

struct DatePickerHeaderView: View {
  @EnvironmentObject var filterObject: FilterObject
  @Binding var view : macosDatePickerEnum
  var body: some View {
    HStack(alignment: .center) {
      HStack {
        Spacer()
        Button {
          view = .Relative
          filterObject.relativeRange = RelativeRangeFilter(period: .Hours, value: 1)
          filterObject.absoluteRange = nil
        } label: {
          Text("Relative")
            .padding(.vertical, 10)
            .padding(.horizontal,15)
            .background(view == .Relative ? Color("Background") : Color.clear)
            .contentShape(Rectangle())
            .clipShape(.rect(
              topLeadingRadius: 5,
              bottomLeadingRadius: 0,
              bottomTrailingRadius: 0,
              topTrailingRadius: 5
            )
            )
        }
        .buttonStyle(PlainButtonStyle())
        
        Button {
          view = .Absolute
          filterObject.absoluteRange = AbsoluteDateRangeObject(from:Date.now, to:Date.now)
          filterObject.absoluteRange?.toNow = true
          filterObject.relativeRange = nil
        } label: {
            Text("Absolute")
            .padding(.vertical, 10)
            .padding(.horizontal,15)
            .background(view == .Absolute ? Color("Background") : Color.clear)
            .contentShape(Rectangle())
            .clipShape(.rect(
              topLeadingRadius: 5,
              bottomLeadingRadius: 0,
              bottomTrailingRadius: 0,
              topTrailingRadius: 5
            )
            )
        }
        .buttonStyle(PlainButtonStyle())
        
        
      }
      
//      if filterObject.relativeRange != nil || filterObject.absoluteRange != nil {
//        Button {
//          filterObject.relativeRange = nil
//          filterObject.absoluteRange = nil
//        } label: {
//          VStack(alignment: .leading, spacing: 10) {
//            Text("Clear")
//              .font(.system(size: 16))
//          }
//          .padding(.vertical, 8)
//          .padding(.horizontal, 10)
//          .foregroundColor(.white)
//          .background(Color("WarnButton"))
//          .cornerRadius(5)
//        }.buttonStyle(PlainButtonStyle())
//      }
      
//      Spacer()
    }
    .frame(maxWidth: .infinity)
    .background(Color("Button"))
  }
}


struct macosDatePickerAbsoluteView: View {

  @EnvironmentObject var filterObject: FilterObject
  
  @State private var fromDate = Date()
  @State private var toDate = Date()
  
  @State private var showFromDatePicker = true
  @State private var showToDatePicker = false
  var body: some View {
      VStack {
  
        HStack(spacing:0)  {
          Text("From:")
            .frame(width: 35, alignment: .trailing)
          
          DatePicker("", selection: $fromDate)
         
          Spacer()
        }
        
        Rectangle().fill(Color("BackgroundAlt"))
          .frame(maxWidth: .infinity)
          .frame(height: 2)
        
        HStack(spacing:0) {
          Text("To:")
            .frame(width: 35, alignment: .trailing)
            
          
          DatePicker("", selection: $toDate)
          
          Spacer()
        }

      }
      .padding(10)
      .onChange(of: fromDate) { newValue in
        filterObject.relativeRange = nil
        filterObject.absoluteRange = AbsoluteDateRangeObject(from:fromDate, to:toDate)
      }
      .onChange(of: toDate) { newValue in
        filterObject.relativeRange = nil
        filterObject.absoluteRange = AbsoluteDateRangeObject(from:fromDate, to:toDate)
      }
  }

}

struct DatePickerButtonsView: View {
  @Binding var selection: macosSearchViewEnum
  @ObservedObject var filterObject : FilterObject
  var body: some View {
    VStack {
      DatePickerButtonRow(filterObject: filterObject, selection: $selection, buttons: [
        DatePickerButtonConfig(title: "Last 5 mins", value: 5, period: .Minutes),
        DatePickerButtonConfig(title: "Last hour", value: 1, period: .Hours)
      ])
      DatePickerButtonRow(filterObject: filterObject, selection: $selection, buttons: [
        DatePickerButtonConfig(title: "Last day", value: 1, period: .Days),
        DatePickerButtonConfig(title: "Last week", value: 1, period: .Weeks)
      ])
      DatePickerButtonRow(filterObject: filterObject, selection: $selection, buttons: [
        DatePickerButtonConfig(title: "Last month", value: 1, period: .Months),
        DatePickerButtonConfig(title: "Last year", value: 1, period: .Years)
      ])
    }
  }
}

struct DatePickerButtonRow: View {
  @ObservedObject var filterObject : FilterObject
    @Binding var selection: macosSearchViewEnum
    var buttons: [DatePickerButtonConfig]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(buttons, id: \.title) { config in
              DatePickerButton(filterObject:filterObject, selection: $selection, config: config)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct DatePickerButtonConfig {
    var title: String
    var value: Double
    var period: SearchDateTimePeriods
}

struct DatePickerButton: View {
  @ObservedObject var filterObject : FilterObject
    @Binding var selection: macosSearchViewEnum
    var config: DatePickerButtonConfig
    var buttonWidth : CGFloat? = .infinity

    var body: some View {
        Button {
            updateDateObject(input: config.value, period: config.period)
            selection = .None
        } label: {
            Text(config.title)
                .padding(.vertical, 10)
                .frame(maxWidth: buttonWidth)
                .foregroundColor(.white)
                .background(existingTime(input: config.value, period: config.period) ? Color("ButtonHighlighted") : Color("Button"))
                .cornerRadius(5)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(PlainButtonStyle())
    }

    func updateDateObject(input: Double, period: SearchDateTimePeriods) {
        if filterObject.relativeRange == nil {
            filterObject.relativeRange = RelativeRangeFilter()
        }
      filterObject.relativeRange = RelativeRangeFilter(period: period, value: input)
      if let dateField = filterObject.dateField {
        filterObject.sort = SortObject(order: .Descending, field: dateField)
      }
        
    }

    func existingTime(input: Double, period: SearchDateTimePeriods) -> Bool {
        if let dateObj = filterObject.relativeRange {
            return dateObj.value == input && dateObj.period == period
        }
        return false
    }
}
