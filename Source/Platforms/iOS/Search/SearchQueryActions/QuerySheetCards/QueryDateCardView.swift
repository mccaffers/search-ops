// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct QueryDateCardView: View {
  
  @State var showingDateInput = false
  @Binding var selectedIndex: String
  //    @EnvironmentObject var dateObj : DateRangeObj
  @EnvironmentObject var filterObject : FilterObject
  @State var refresh = UUID()
  
  func UpdateDateObject(input: Double, period: SearchDateTimePeriods) {
    
    if filterObject.relativeRange == nil {
      filterObject.relativeRange = RelativeRangeFilter()
    }
    
    filterObject.relativeRange?.period = period
    filterObject.relativeRange?.value = input
    refresh=UUID()
    
  }
  
  func ExistingTime(input: Double, period: SearchDateTimePeriods) -> Bool {
    if let dateObj = filterObject.relativeRange {
      if dateObj.value == input &&
          dateObj.period == period {
        return true
      }
    }
    return false
  }
  
  
  func getDate(_ dateInput: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd / MM / yyyy" // Full day, Monday
    return dateFormatter.string(from: dateInput)
  }
  
  
  func getHour(_ dateInput: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss a" // Full day, Monday
    return dateFormatter.string(from: dateInput)
  }
  
  var body: some View {
    
    Button {
      showingDateInput=true
    } label: {
      
      HStack {
        VStack(alignment: .leading, spacing:10){
          HStack (alignment:.center){
            
            Text("Date Range")
              .font(.system(size: 24, weight:.bold))
              .foregroundColor(Color("TextColor"))
            //                        if filterObject.dateField != nil {
            
            if filterObject.relativeRange == nil && filterObject.absoluteRange == nil {
              
              HStack(spacing:3) {
                //                                    Text(Image(systemName: "slash.circle.fill"))
                Text("Not Set")
              }
              //                                .font(.system(size: 14))
              .padding(8)
              .foregroundColor(Color("TextColor"))
              .background(Color("LabelBackgrounds"))
              .cornerRadius(5)
              
            } else {
              
              Button {
                filterObject.relativeRange = nil
                filterObject.absoluteRange = nil
                refresh=UUID()
              } label: {
                VStack(
                  alignment: .leading,
                  spacing: 10
                ) {
                  Text("Clear")
                    .font(.system(size: 16))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .foregroundColor(.white)
                .background(Color("WarnButton"))
                .cornerRadius(5)
              }
            }
            
            Spacer()
            
            Text(Image(systemName: "chevron.right"))
              .font(.system(size: 22))
              .foregroundColor(Color("LabelBackgrounds"))
            
            
            
          }.frame(maxWidth: .infinity) .frame(height: 40)
          
          if filterObject.dateField == nil {
            HStack (alignment:.top, spacing:5) {
              Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24, weight:.light))
                .foregroundColor(.orange)
                .padding(.trailing, 5)
              VStack(alignment:.leading,spacing:10){
                Text("Date Range is not active")
                  .font(.system(size: 16, weight:.semibold))
                  .padding(.top,2)
                Text("A field of Date type needs to be selected for the Date Range to be active")
              }
            }
            .font(.system(size: 14))
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment:.leading)
            .multilineTextAlignment(.leading)
            
          }
          if filterObject.relativeRange != nil {
            HStack(spacing:5) {
              Text(filterObject.relativeRange?.value.string ?? "")
              Text(filterObject.relativeRange?.period.rawValue ?? "")
            }
            .foregroundColor(Color("TextColor"))
            //                        .padding(.vertical, 10)
          } else if filterObject.absoluteRange != nil {
            VStack(spacing:10) {
              HStack {
                Text("From")
                  .frame(width: 40, alignment:.trailing)
                  .padding(.trailing, 10)
                Text(getDate((filterObject.absoluteRange?.from ?? Date.now)))
                Text(getHour((filterObject.absoluteRange?.from ?? Date.now)))
                
              }
              HStack {
                Text("To")
                  .frame(width: 40, alignment:.trailing)
                  .padding(.trailing, 10)
                Text(getDate((filterObject.absoluteRange?.to ?? Date.now)))
                Text(getHour((filterObject.absoluteRange?.to ?? Date.now)))
              }
            }
            .foregroundColor(Color("TextColor"))
            .frame(maxWidth: .infinity, alignment:.leading)
            .padding(.top, 10)
            //                        .padding(.vertical, 10)
          } else {
            
            Text("Quick Buttons:")
              .font(.system(size: 14))
              .foregroundColor(Color("TextColor"))
            
            VStack {
            
              HStack (spacing:10) {
                
                Button {
                  UpdateDateObject(input: 15, period: SearchDateTimePeriods.Minutes)
                } label: {
                  
                  Text("Last 5 mins")
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(ExistingTime(input: 5, period: .Minutes) ?
                                Color("ButtonHighlighted") : Color("Button"))
                    .cornerRadius(5)
                }.frame(maxWidth: .infinity)
                
                Button {
                  UpdateDateObject(input: 1, period: SearchDateTimePeriods.Hours)
                } label: {
                  
                  Text("Last hour")
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(ExistingTime(input: 1, period: .Hours) ?
                                Color("ButtonHighlighted") : Color("Button"))
                    .cornerRadius(5)
                }.frame(maxWidth: .infinity)
                
                
                
                
              }.frame(maxWidth: .infinity)
              
              HStack(spacing:10){
                Button {
                  UpdateDateObject(input: 1, period: SearchDateTimePeriods.Days)
                } label: {
                  Text("Last day")
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(ExistingTime(input: 1, period: .Days) ?
                                Color("ButtonHighlighted") : Color("Button"))
                    .cornerRadius(5)
                }
                
                Button {
                  UpdateDateObject(input: 1, period: SearchDateTimePeriods.Weeks)
                } label: {
                  
                  Text("Last week")
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(ExistingTime(input: 1, period: .Weeks) ?
                                Color("ButtonHighlighted") : Color("Button"))
                    .cornerRadius(5)
                }.frame(maxWidth: .infinity)
              }.frame(maxWidth: .infinity)
              
              HStack (spacing:10) {
                
                
                
                Button {
                  UpdateDateObject(input: 1, period: SearchDateTimePeriods.Months)
                } label: {
                  
                  Text("Last month")
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(ExistingTime(input: 1, period: .Months) ?
                                Color("ButtonHighlighted") : Color("Button"))
                    .cornerRadius(5)
                }.frame(maxWidth: .infinity)
                
                Button {
                  UpdateDateObject(input: 1, period: SearchDateTimePeriods.Years)
                } label: {
                  Text("Last year")
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(ExistingTime(input: 1, period: .Years) ?
                                Color("ButtonHighlighted") : Color("Button"))
                    .cornerRadius(5)
                }
                
                
              }.frame(maxWidth: .infinity)
            }
            
            
          }
          
          
        }.padding(.bottom, 10)
        
        //                Spacer()
        
        //                if filterObject.dateField != nil {
        //                    Text(Image(systemName: "chevron.right"))
        //                        .font(.system(size: 22))
        //                        .foregroundColor(Color("LabelBackgroundFocus"))
        //                        .padding(.vertical, 5)
        //                        .padding(.horizontal, 15)
        //                        .cornerRadius(5)
        //                }
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .padding(.horizontal, 15)
    .background(Color("BackgroundAlt"))
    .cornerRadius(5)
    .padding(.horizontal, 10)
    .id(refresh)
#if os(iOS)
    .navigationDestination(isPresented:$showingDateInput, destination: {
      SearchQueryDateSheetTimePicker(selectedIndex: $selectedIndex)
    })
#endif

    .onAppear {
      
      if filterObject.absoluteRange != nil || filterObject.relativeRange != nil {
        refresh=UUID()
      }
      //            print(filterObject.absoluteRange?.from.formatted())
    }
    //        .foregroundColor(.white)
    //        .disabled( filterObject.dateField == nil )
  }
}
