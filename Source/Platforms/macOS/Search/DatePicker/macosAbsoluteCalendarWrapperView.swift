// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosAbsoluteCalendarWrapperView: View {
  
  @State private var calendarHeight: CGFloat = 0
  @Binding var selectedDate : Date
  @State var dateText: String = ""
  
  @State var invalidDate = false
  @State private var workItem: DispatchWorkItem?
  @State private var typing = false
  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
  }
  
  var cornerRadius : (topLeadingRadius: CGFloat, bottomLeadingRadius: CGFloat, bottomTrailingRadius: CGFloat, topTrailingRadius: CGFloat) = (0,5,5,0)
  
//  (
//    topLeadingRadius: 0,
//    bottomLeadingRadius: 5,
//    bottomTrailingRadius: 5,
//    topTrailingRadius: 0
//  )
  
  func getYear(from date: Date, using calendar: Calendar = .current) -> Int? {
      let components = calendar.dateComponents([.year], from: date)
      return components.year
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top, spacing:0){
        macosCalendarView(calendar: Calendar(identifier: .gregorian),
                          selectedDate: $selectedDate)
        .background(
          GeometryReader { geometry in
            Color.clear
              .onAppear {
                calendarHeight = geometry.size.height
              }
              .onChange(of: geometry.size.height) { newHeight in
                calendarHeight = newHeight
              }
          }
        )
        .frame(maxWidth: .infinity)
        .padding(.trailing, 5)
        ScrollViewReader { value in
          ScrollView {
            let selectedHour = Calendar.current.component(.hour, from: selectedDate)
            VStack(alignment: .leading) {
              ForEach(0..<24) { hour in
                Button {
                  selectedDate = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate)!
                  
                } label: {
                  Text(String(format: "%02d:00", hour % 24))
                    .frame(maxWidth: .infinity, alignment:.center)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
                    .background(selectedHour == hour ? Color("CalendarSelection") : Color("Button").opacity(0.4))
                    .clipShape(.rect(cornerRadius: 5))
                }
                .buttonStyle(PlainButtonStyle())
                .id(hour)
              }
            }
            .padding(.leading, 5)
            .onAppear {
              //              DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
              value.scrollTo(selectedHour+3)
              //              }
            }
          }
          .scrollIndicators(.never)
          .frame(maxWidth: 55)
          .frame(height: calendarHeight)
        }
        
      }
      
      HStack(spacing:5) {
        
        TextField("", text: $dateText)
          .textFieldStyle(PlainTextFieldStyle())
          .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
//          .font(.system(size: 15))
          .frame(height: 30)
          .background(Color("Button"))
          .clipShape(.rect(cornerRadius: 5))
          .overlay(
            RoundedRectangle(cornerRadius: 5)
              .stroke(Color("BackgroundAlt"), lineWidth: 1)
          )
          .onChange(of: dateText) { newValue in
            typing = true
            // Cancel the previous work item if it exists
            workItem?.cancel()
            
            // Create a new work item
            workItem = DispatchWorkItem {
              typing = false
            }
            
            if let parsedDate = dateFormatter.date(from: newValue),
               let year = getYear(from: parsedDate),
                year >= 1900 {
              selectedDate = parsedDate
              invalidDate = false
            } else {
              // Handle invalid date format
              withAnimation {
                invalidDate = true
              }
            }
            
            // Schedule the new work item with a delay of 3 seconds
            if let workItem = workItem {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
            }
            
          }
          .onAppear {
            dateText = dateFormatter.string(from: Date())
          }
          .onChange(of: selectedDate) { newValue in
            
            // typing bool prevents a loop of
            // changing the date value
            // which interfers with the typing
            if !typing,
                dateFormatter.string(from: newValue) != dateText {
              dateText = dateFormatter.string(from: newValue)
            }
            
          }
        
        if invalidDate {
          Image(systemName: "xmark")
            .foregroundStyle(.red)
            .padding(.vertical, 10)
        } else {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .padding(.vertical, 10)
        }
      }
      
      if invalidDate {
        Text("Expecting YYYY-MM-DD HH:MM:SS")
          .font(.subheadline)
          .padding(.leading, 5)
          .italic()
      }
        
      
      //      .overlay(
      //        RoundedRectangle(cornerRadius: 5)
      //          .stroke(Color("Button"), lineWidth: 1)
      //      )
      
    }
    .padding(10)
    .background(Color("BackgroundAlt"))
    .clipShape(.rect(topLeadingRadius: cornerRadius.topLeadingRadius,
                     bottomLeadingRadius: cornerRadius.bottomLeadingRadius,
                     bottomTrailingRadius: cornerRadius.bottomTrailingRadius,
                     topTrailingRadius: cornerRadius.topTrailingRadius))
    
                     
  }
}
