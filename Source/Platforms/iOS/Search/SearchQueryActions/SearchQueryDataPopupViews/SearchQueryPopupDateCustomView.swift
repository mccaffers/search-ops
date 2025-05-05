// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchQueryPopupDateCustomView: View {
  
  @Binding var showingCustomView : Bool
  
  @State var originalDate : Date = Date.now
  @Binding var dateObject : Date
  
  @State var localValue = ""
  @State var selected = false
  @FocusState private var focusedField: FocusField?
  
  @State var timePeriodValue : SearchDateTimePeriods = SearchDateTimePeriods.Minutes
  @State var negative = false
  
  func calulateTime() {
    // math of timePeriodValue
    var value = Double(localValue) ?? 0.0
    if negative {
      value = -value
    }
    var calculatedValue = DateTools.calculateSecondsByPeriod(value:value, period: timePeriodValue)
    
    var localDate = Date(timeIntervalSince1970: originalDate.timeIntervalSince1970)
    localDate.addTimeInterval(TimeInterval(calculatedValue))
    dateObject = localDate
    
  }
  
  var body: some View {
    VStack {
      HStack {
        HStack {
          Button {
            showingCustomView = false
          } label: {
            Image(systemName: "chevron.left")
              .padding(10)
              .background(Color("Button"))
              .cornerRadius(5)
          }
        }.frame(maxWidth: .infinity, alignment:.leading)
        HStack {
          Text("Custom Value")
        }.frame(maxWidth: .infinity, alignment:.center)
        HStack {
          Spacer()
        }.frame(maxWidth: .infinity, alignment:.leading)
        
        
      }.padding(.bottom, 5)
      
      HStack {
        Button {
          negative.toggle()
          calulateTime()
        } label: {
          Text(negative ? "-" : "+")
            .padding(.vertical, 10)
            .frame(width: 50)
            .background(Color("Button"))
            .cornerRadius(5)
        }
        
        TextField("Value", text: $localValue)
          .multilineTextAlignment(.trailing)
#if os(iOS)
          .keyboardType(.decimalPad)
#endif
          .textFieldStyle(SelectedTextStyle(focused: $selected, padding:8))
          .focused($focusedField, equals: .field)
          .onChange(of: localValue){ newValue in
            let filtered = newValue.filter { "0123456789.".contains($0) }
            if filtered != newValue {
              localValue = filtered
            }
            
            calulateTime()
          }
          .onChange(of: focusedField, perform: { newValue in
            // selected the textfield view, needs a negative check on selected
            // or swiftui loops forever
            
            if selected != false && newValue == nil   {
              selected = false
            }
            if selected != true && newValue == .field {
              selected = true
            }
          })
          .frame(maxWidth: .infinity)
        
        Menu {
          ForEach(SearchDateTimePeriods.allCases, id: \.self) { item in
            Button {
              timePeriodValue=item
            } label: {
              Text(item.rawValue)
            }
          }
        } label: {
          VStack {
            HStack (spacing: 5) {
              Text(timePeriodValue.rawValue + " ago")
            }
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .center)
          }
          .background(Color("Button"))
          .cornerRadius(5)
        }.frame(maxWidth: .infinity, alignment: .center)
          .onChange(of: timePeriodValue) { newValue in
            calulateTime()
          }
        
      }
    }
    .padding(10)
    .background(Color("BackgroundAlt"))
    .cornerRadius(5)
    .onAppear {
      originalDate=dateObject
    }
  }
}
