// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchQueryDatePopupRelative: View {
  
  var queryDate : Date
  @Binding var dateObject : Date
  @Binding var selected : DateField
  
  @State var showingCustomView = false
  var body: some View {
    VStack (spacing:5){
      
      Text("Date Adjustments")
        .foregroundColor(Color("TextSecondary"))
        .font(.system(size:14))
        .frame(maxWidth: .infinity, alignment:.leading)
      
      if showingCustomView {
        SearchQueryPopupDateCustomView(showingCustomView: $showingCustomView,
                                       dateObject: $dateObject)
      } else {
        VStack {
          HStack {
            
            Button {
              
              // subtract 5 minutes from date
              dateObject.addTimeInterval(TimeInterval(+5.0 * 60.0))
            } label: {
              Text("- 5 minutes")
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .background(Color("Button"))
                .cornerRadius(5)
            }
            
            Button {
              
              // subtract 5 minutes from date
              dateObject.addTimeInterval(TimeInterval(-5.0 * 60.0))
              
              
            } label: {
              Text("+ 5 minutes")
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .background(Color("Button"))
                .cornerRadius(5)
            }
            
            
          }
          
          HStack {
            
            
            Button {
              //						showDateInputView=nil
              var oneday = 60.0 * 60.0 * 24 // 60 * 60 seconds * 24 = 1 (day)
              dateObject.addTimeInterval(TimeInterval(-oneday))
            } label: {
              Text("- 1 day")
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .background(Color("Button"))
                .cornerRadius(5)
            }
            
            Button {
              
              // subtract 5 minutes from date
              var oneday = 60.0 * 60.0 * 24 // 60 * 60 seconds * 24 = 1 (day)
              dateObject.addTimeInterval(TimeInterval(oneday))
            } label: {
              Text("+ 1 day")
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .background(Color("Button"))
                .cornerRadius(5)
            }
          }
          
          HStack {
            Button {
              //						showDateInputView=nil
              dateObject = queryDate
            } label: {
              HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text("Query Date")
              }
              .padding(.vertical, 10)
              .frame(maxWidth: .infinity)
              .foregroundColor(.white)
              .background(Color("Button"))
              .cornerRadius(5)
            }
            
            Button {
              showingCustomView = true
            } label: {
              HStack {
                Image(systemName: "keyboard")
                Text("Custom")
              }
              .padding(.vertical, 10)
              .frame(maxWidth: .infinity)
              .foregroundColor(.white)
              .background(Color("Button"))
              .cornerRadius(5)
            }
          }
          
        }
        .padding(10)
        .background(Color("BackgroundAlt"))
        .cornerRadius(5)
      }
    }.onChange(of: selected) { newValue in
      print("seg " + newValue.rawValue)
      showingCustomView=false
    }
  }
}
