// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

import SwiftyJSON

struct macosAppHistory: View {
  
  @ObservedObject var searchManager : SearchHistoryDataManager
  
  @State var showNavigationBar = false
  @State var showingRequestJson = false
  @State var event : LogEvent? = nil
  
  @ObservedObject var serverObjects: HostsDataManager
  
//  @Binding var firstSearchAfterSelectingIndex : Bool
  var request : (_ selectedHost: HostDetails, _ selectedIndex: String, _ filterObject: FilterObject) -> ()
  
  func formattedDateString(from date: Date) -> String {
    let dateFormatter = DateFormatter()
    
    // Set the locale to ensure the day and month names are in English
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    
    // Set the date format for the time including milliseconds
    dateFormatter.dateFormat = "HH:mm:ss"
    let timePart = dateFormatter.string(from: date)
    
    // Combine date part with time part
    let formattedString = "\(timePart)"
    
    return formattedString
  }
  
  func formattedDateStringCalendar(from date: Date) -> String {
      let dateFormatter = DateFormatter()
      
      // Set the locale to ensure the day and month names are in English
      dateFormatter.locale = Locale(identifier: "en_US_POSIX")
      
      // Set the date format for the full string
      dateFormatter.dateFormat = "EEEE d MMMM yyyy"
      
      let dateString = dateFormatter.string(from: date)
      
      // To handle the ordinal suffix for the day
      let calendar = Calendar.current
      let day = calendar.component(.day, from: date)
      
      let suffix: String
      switch day {
      case 11, 12, 13:
          suffix = "th"
      default:
          switch day % 10 {
          case 1:
              suffix = "st"
          case 2:
              suffix = "nd"
          case 3:
              suffix = "rd"
          default:
              suffix = "th"
          }
      }
      
      // Replace the day part with the ordinal day
      let dayWithSuffix = "\(day)\(suffix)"
      
      // Use a regular expression to replace only the day part
      let pattern = "\\b\(day)\\b"
      let regex = try! NSRegularExpression(pattern: pattern, options: [])
      let range = NSRange(dateString.startIndex..., in: dateString)
      let formattedString = regex.stringByReplacingMatches(in: dateString, options: [], range: range, withTemplate: dayWithSuffix)
      
      return formattedString
  }
  
  
  private func shouldShowHeader(previous: SearchEvent, for event: SearchEvent, at index: Int) -> Bool {
    if index == 0 {
      return true
    }
    
    if areDatesSameDay(date1: previous.date, date2: event.date) {
      return false
    } else {
      return true
    }
    
  }
  
  func areDatesSameDay(date1: Date, date2: Date) -> Bool {
    let calendar = Calendar.current
    return calendar.isDate(date1, inSameDayAs: date2)
  }
  
  private func formattedDateHeader(from date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "EEEE"
    return dateFormatter.string(from: date)
  }
  
  let columns = [GridItem(.flexible(), alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)]
  
  @State var width : CGFloat = 300
  @State var height : CGFloat = 100
  
  func isEven(_ number: Int) -> Bool {
    return number % 2 == 0
  }
  
  func randomString(length: Int) -> String {
         let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
         return String((0..<length).map{ _ in letters.randomElement()! })
     }
  
  var body: some View {
    GeometryReader { geo in
      Color.clear
        .onAppear {
          width = geo.size.width
          height = geo.size.height
          print("Width: \(geo.size.width), Height: \(geo.size.height)")
        }
        .onChange(of: geo.size) { newSize in
          width = newSize.width
          height = newSize.height
          print("Width: \(newSize.width), Height: \(newSize.height)")
        }
      
      if searchManager.items.count > 0 {
        ScrollView {
        LazyVStack(spacing:0) {
          
          let filteredByDate = searchManager.groupByDate()
          
          ForEach(filteredByDate.keys.sorted {$0 > $1}, id:\.self) { el in
            
            //            var theDate = filteredByDate[el] as? Date
            Text(formattedDateStringCalendar(from: el))
              .font(.system(size: 15))
              .padding(.bottom, 5)
              .frame(maxWidth: .infinity, alignment: .leading)
            
            if let myList = filteredByDate[el] {
              
              
              HStack(spacing:0) {
                HStack(spacing:0){
                  Text("Host")
                    .padding(.leading, 5)
                }
                .frame(width: width*0.15, alignment:.leading)
                
                Text("Index")
                  .frame(width: width*0.15, alignment:.leading)
                Text("Query String")
                  .frame(width: width*0.4, alignment:.leading)
                Text("Date Range")
                  .frame(width: width*0.3, alignment:.leading)
              }
              .padding(.vertical, 5)
              .foregroundColor(Color("LabelBackgroundBorder"))
              .background(Color("BackgroundAlt"))
              .frame(maxWidth: .infinity)
              .padding(.bottom, 2)
              
              let sortedList = myList.sorted { $0.date > $1.date }
              VStack(spacing:0) {
                ForEach(sortedList.indices, id:\.self) { index in
                  
                  if let historySelectedHost = serverObjects.items.first(where: {$0.id == sortedList[index].host}) {
                    
                    macosSearchHistoryButton(serverObjects:serverObjects,
                                             item: sortedList[index],
                                             firstSearchAfterSelectingIndex: .constant(false),
                                             request: request,
                                             width: width,
                                             host: historySelectedHost)
                    
                    
                    .padding(.bottom, 1)
                  }
                  
                  
                }
              }.padding(.bottom, 10)
            }
            
          }
        }.frame(maxWidth: .infinity)
      }
        .scrollIndicators(.never)
      } else {
     
          DynamicPlaceholderRowsView(width:$width,
                                     height:$height)
       
//
      }
    }
    .frame(maxHeight: .infinity)
    .onAppear {
      searchManager.refresh()
    }
    .navigationDestination(isPresented:$showingRequestJson, destination: {
      if let event = event {
        SettingsDetailMainView(event:event)
      }
    })
  }
}




struct DynamicPlaceholderRowsView: View {
  @Binding var width : CGFloat
  @Binding var height: CGFloat
  
  func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return String((0..<length).map{ _ in letters.randomElement()! })
  }
  
  var body: some View {
    
    VStack(spacing: 0) {
      // Header
      HStack(spacing: 0) {
        HStack(spacing: 0) {
          Text("HostHost")
            .padding(.leading, 5)
        }
        .frame(width: width * 0.15, alignment: .leading)
        
        Text("Index")
          .frame(width: width * 0.15, alignment: .leading)
        Text("Query String")
          .frame(width: width * 0.4, alignment: .leading)
        Text("Date Range")
          .frame(width: width * 0.3, alignment: .leading)
      }
      .foregroundColor(Color("LabelBackgroundBorder"))
      .font(.system(size: 20))
      .frame(height: 40)
      
      // Dynamic rows
      let availableHeight = height - 40 // Subtracting header height and padding
      let rowHeight: CGFloat = 30 // Set a fixed height for each row
      let numberOfRows = Int(availableHeight / rowHeight)
      
      ForEach(0..<numberOfRows, id: \.self) { _ in
        HStack(spacing: 0) {
          HStack(spacing: 0) {
            Text(randomString(length: Int.random(in: 5...20)))
              .padding(.leading, 5)
          }
          .frame(width: width * 0.15, alignment: .leading)
          
          Text(randomString(length: Int.random(in: 4...20)))
            .frame(width: width * 0.15, alignment: .leading)
          
          Text(randomString(length: Int.random(in: 10...55)))
            .frame(width: width * 0.4, alignment: .leading)
          
          Text(randomString(length: Int.random(in: 2...25)))
            .frame(width: width * 0.3, alignment: .leading)
        }
        .font(.system(size: 16))
        .frame(height: rowHeight)
      }
    }
    .padding(.top, 5)
    .background(Color("BackgroundAlt"))
    .clipShape(.rect(cornerRadius: 5))
    .redacted(reason: .placeholder)
    .opacity(0.5)
  }
}
