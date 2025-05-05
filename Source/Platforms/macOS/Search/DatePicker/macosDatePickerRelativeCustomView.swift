// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosDatePickerRelativeCustomView: View {
  
  @State var showingPeriods = false
  @State var relativeText =  "60"
  @Binding var showingCustomValues : Bool
  @State var datePeriod : SearchDateTimePeriods? = nil
  @ObservedObject var filterObject: FilterObject
  @Binding var selection: macosSearchViewEnum
  
    var body: some View {
      if showingCustomValues {
        
        if showingPeriods {
          VStack {
            HStack {
              Button {
                datePeriod = .Seconds
                showingPeriods = false
              } label: {
                Text("Seconds")
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 10)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
              }.buttonStyle(PlainButtonStyle())
              
              Button {
                datePeriod = .Minutes
                showingPeriods = false
              } label: {
                Text("Minutes")
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 10)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
              }.buttonStyle(PlainButtonStyle())
            }
            
            HStack {
              Button {
                datePeriod = .Hours
                showingPeriods = false
              } label: {
                Text("Hours")
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 10)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
              }.buttonStyle(PlainButtonStyle())
              
              Button {
                datePeriod = .Days
                showingPeriods = false
              } label: {
                Text("Days")
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 10)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
              }.buttonStyle(PlainButtonStyle())
            }
            
          }.padding(10)
        } else {
          VStack {
            
            HStack {
              
              Button {
                showingCustomValues = false
              } label: {
                HStack {
                  Image(systemName: "arrowshape.turn.up.backward.fill")
                  Text("Quick buttons")
                }
                .padding(10)
                .background(Color("Button"))
                .clipShape(.rect(cornerRadius: 5))
              }.buttonStyle(PlainButtonStyle())
              
              Spacer()
              
              
              
            }.padding(.top, 10)
            
            
            HStack {
              
              TextField("", text: $relativeText)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                .frame(height: 38)
                .background(Color("Button"))
                .clipShape(.rect(cornerRadius: 5))
                .overlay(
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(Color("BackgroundAlt"), lineWidth: 1)
                )
                .frame(maxWidth: .infinity)
              
              Button {
                showingPeriods = true
              } label: {
                HStack {
                  if let datePeriod = datePeriod {
                    Text(datePeriod.rawValue)
                  }
                  Image(systemName: "chevron.up.chevron.down")
                }
                .padding(10)
                .background(Color("Button"))
                .cornerRadius(5)
              }
              .buttonStyle(PlainButtonStyle())
              
              Button {
                if let datePeriod = datePeriod {
                  filterObject.relativeRange = RelativeRangeFilter(period: datePeriod,
                                                                   value: Double(relativeText) ?? 0)
                  if let dateField = filterObject.dateField {
                    filterObject.sort = SortObject(order: .Descending, field: dateField)
                  }
                }
                selection = .None
              } label: {
                Text("Set")
                  .padding(10)
                  .background(Color("PositiveButton"))
                  .clipShape(.rect(cornerRadius: 5))
              }.buttonStyle(PlainButtonStyle())
            }
            
           
          }
          .padding(.horizontal, 10)
          .background(Color("Background"))
          .padding(.bottom, 10)
          .onAppear {
            if let value = filterObject.relativeRange?.value {
              relativeText = String(value)
            }
            if let period = filterObject.relativeRange?.period {
              if datePeriod == nil {
                datePeriod = period
              }
            }
            if datePeriod == nil {
              datePeriod = .Minutes
            }
          }
          
          
          HStack {
            Spacer()
            if let datePeriod = datePeriod {
              Text(relativeText + " " + datePeriod.rawValue)
            }
            Image(systemName: "chevron.right")
            Text("Now")
            Spacer()
          
          }
          .padding(.vertical, 10)
          .frame(maxWidth: .infinity)
          .background(Color("Button"))
          
        }
      } else {
        Button {
          showingCustomValues = true
        } label: {
          Text("Custom")
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(Color("Button"))
            .cornerRadius(5)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 10)
        .padding(.bottom, 10) 
      }
    }
}

