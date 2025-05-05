// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct iosSearchHistoryList: View {
  
  @EnvironmentObject var orientation : Orientation
  
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
  
  private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
  
  var indexWidth : CGFloat {
    (width * 0.33) - (idiom == .pad ? 20 : 0)
  }
  
  var queryWidth : CGFloat {
    (width * 0.33) - (idiom == .pad ? 20 : 0)
  }
  
  var dateWidth : CGFloat {
    (width * 0.33) - (idiom == .pad ? 20 : 0)
  }
  
  var itemLimit = 0
  func sortedList (myList:[SearchEvent]) -> [SearchEvent] {
    return myList.sorted { $0.date > $1.date }
  }
  
  func sortedKeys () -> Array<Date> {
    let filteredByDate = searchManager.groupByDate()
    if itemLimit == 0 {
      return Array(filteredByDate.keys.sorted {$0 > $1})
    } else {
      return Array(filteredByDate.keys.sorted {$0 > $1}.prefix(2))
    }
  }
  

  var body: some View {
    GeometryReader { geo in
      Color.clear
        .onAppear {
          width = geo.size.width
          height = geo.size.height
//          print("Width: \(geo.size.width), Height: \(geo.size.height)")
        }
        .onChange(of: geo.size) { newSize in
          width = newSize.width
          height = newSize.height
//          print("Width: \(newSize.width), Height: \(newSize.height)")
        }

      
      if searchManager.items.count > 0 {
        ScrollView {
          LazyVStack(spacing:0) {
            
            let filteredByDate = searchManager.groupByDate()
            ForEach(sortedKeys(), id:\.self) { el in
              
              //            var theDate = filteredByDate[el] as? Date
              Text(formattedDateStringCalendar(from: el))
                .bold()
                .font(.system(size: 13))
                .padding(.bottom, 5)
                .padding(.leading, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, idiom == .pad ? 20 : 0)
              
              if let myList = filteredByDate[el] {
                
                
                HStack(spacing:0) {
                  HStack(spacing:0){
                    Text("Host / Indices")
                      .padding(.leading, 3)
                  }
                  .frame(width: indexWidth, alignment:.leading)
       
                  Text("Query String")
                    .frame(width: queryWidth, alignment:.leading)
                  
                  Text("Date")
                    .frame(width: dateWidth, alignment:.leading)
                }
                .font(.system(size: 12))
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color("LabelBackgroundBorder"))
                .background(Color("BackgroundAlt"))
                .padding(.bottom, 2)
                .padding(.horizontal, idiom == .pad ? 20 : 0)
         
                
               var sortedList = sortedList(myList: myList)
                VStack(spacing:0) {
                  ForEach(sortedList.indices, id:\.self) { index in
                    
                    if let historySelectedHost = serverObjects.items.first(where: {$0.id == sortedList[index].host}) {
                      
                      iOSSearchHistoryButton(serverObjects:serverObjects,
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
          }
          .frame(maxWidth: .infinity)
          .padding(.top, 10)
          
          
          if !orientation.isLandscape {
            VStack {
              Image(systemName: "hand.draw")
              Text("Swipe down to close")
            }
            .frame(maxWidth: .infinity)
            .font(.footnote)
            .foregroundStyle(Color("TextSecondary"))
            .padding(.bottom, 10)
          }
        }
        .scrollIndicators(.never)
      } else {
        VStack(alignment:.center, spacing:10) {
          Image(systemName: "exclamationmark.magnifyingglass")
            .font(.system(size: 42))
            .padding(.bottom, 10)
          Text("No search history to show at the moment")
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
          Text("Perform a query and your search history will appear here")
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
          Spacer()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, alignment: .center)

      }
    }
    .frame(maxHeight: .infinity)
    .onAppear {
//      searchManager.refresh()
    }
    .navigationDestination(isPresented:$showingRequestJson, destination: {
      if let event = event {
        SettingsDetailMainView(event:event)
      }
    })
  }
}
#endif
