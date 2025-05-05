// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchQueryRelativeCustomInputView: View {
    
    enum FocusField: Hashable {
        case field
    }
    
//    @EnvironmentObject var dateObj : DateRangeObj
    @EnvironmentObject var filterObject : FilterObject
    
    @State var localValue : String = ""
    @State var fromDate : String = ""
    @State var toDate : String = ""
    @State var timePeriodValue : SearchDateTimePeriods = SearchDateTimePeriods.Minutes
    
    @FocusState private var focusedField: FocusField?
    @ObservedObject private var keyboard = KeyboardResponder()
    
    @Binding var localRelativeRangeObject : RelativeRangeFilter
    
    func getToDate() -> String {
        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = "d MMMM YYYY - HH:mm:ss"

        return dateFormatter.string(from: Date.now)
    }

    @State private var selected: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {

        VStack (spacing:10) {
            
            HStack (spacing:10){
                
                TextField("Value", text: $localValue)
                    .multilineTextAlignment(.trailing)
#if os(iOS)
                    .keyboardType(.decimalPad)
              #endif
                    .textFieldStyle(SelectedTextStyle(focused: $selected))
                    .onChange(of: localValue){ newValue in
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if filtered != newValue {
                            localValue = filtered
                        }

                        let output = Double(localValue) ?? 0.0
                        
                        if output != localRelativeRangeObject.value {
//                            localRelativeRangeObject = RelativeRangeFilter()
                            localRelativeRangeObject.value = output
                            localRelativeRangeObject.period = timePeriodValue
//                            dateObj.Refresh()
                            
                        }
//                        if output != dateObj.relativeValue {
//
//                        }
//                        if output != 0.0 {
                            
//
//                        }

                    }
                    .focused($focusedField, equals: .field)
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
//                    .onChange(of: dateObj.refresh) { _ in
//                        //                        if localValue != dateObj.relativeValue.string &&
//                        //                            dateObj.relativeValue.string != "0.0" {
//                        //                            localValue=dateObj.relativeValue.string
//                        //                            timePeriodValue=dateObj.period
//                        //                        }
//                    }
                    .onAppear {
                        //localValue = "5"
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.focusedField = .field
                        }
                        
                        // value has a decimal place of 0.0, so lets just display the first
                        // integer
                        
//                        if let dateObj = filterObject.relativeRange {
                            if localRelativeRangeObject.value.string != "0.0" {
                                
                                if localRelativeRangeObject.value == floor(localRelativeRangeObject.value) {
                                    var doubleString = localRelativeRangeObject.value.string.components(separatedBy: ".")
                                    localValue = doubleString[0]
                                } else {
                                    localValue = localRelativeRangeObject.value.string
                                }
                                timePeriodValue = localRelativeRangeObject.period
                                
                            }
//                        }
                        
                     
                        
//                        if dateObj.relativeValue.string != "0.0" {
//                            if dateObj.relativeValue == floor(dateObj.relativeValue) {
//                                var doubleString = dateObj.relativeValue.string.components(separatedBy: ".")
//                                localValue = doubleString[0]
//                            } else {
//                                localValue=dateObj.relativeValue.string
//                            }
//                            timePeriodValue=dateObj.period
//                        }
                    }.frame(maxWidth: .infinity)
                
                
                HStack (spacing:10){
                    Menu {
                        ForEach(SearchDateTimePeriods.allCases, id: \.self) { item in
                            Button {
                                timePeriodValue=item
                                
                                localRelativeRangeObject.value = Double(localValue) ?? 0.0
                                localRelativeRangeObject.period = timePeriodValue
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
  
                    
                   
                    
                    
                }
                
          
            }
            
            Button {
                filterObject.relativeRange = RelativeRangeFilter()
                filterObject.relativeRange?.period = localRelativeRangeObject.period
                filterObject.relativeRange?.value = localRelativeRangeObject.value
                
                filterObject.absoluteRange = nil
                dismiss()
            } label: {
                HStack {
                    Text("Save")
                    Text(Image(systemName: "square.and.arrow.down"))
                }
								.foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color("PositiveButton"))
                .cornerRadius(5)
						}.padding(.top, 10)
        
        }
        .padding(.horizontal, 15)
        .onChange(of: keyboard.willHide){ _ in
            print("keyboard hidding")
            self.focusedField = .field
        }
        .onAppear {
            if let relativeRangeObject = filterObject.relativeRange {
                localRelativeRangeObject.period = relativeRangeObject.period
                localRelativeRangeObject.value = relativeRangeObject.value
            }
        }
    }
}

