// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct ReleaseNotesListButton: View {
  var releaseDate: Date
  var buttonText: String
  var buttonDescription: String
  var buttonAction: () -> Void
  var activeButton : Bool = false
  var isLatest: Bool = false
  
  var body: some View {
    
    VStack(spacing: 5) {
      HStack {
        HStack(spacing: 5) {
          Text("\(releaseDate, formatter: dayFormatter)")
          Text("\(releaseDate, formatter: monthFormatter)")
          Text("\(releaseDate, formatter: yearFormatter)")
        }
        .font(.system(size: 15))
        .foregroundStyle(activeButton ? Color("TextColor") : Color("TextSecondary"))
        .frame(maxWidth: .infinity, alignment: .leading)
        
        if !activeButton {
          Text("Minor Update")
            .font(.footnote)
            .foregroundStyle(Color("TextSecondary"))
        }
      }
      
    Button(action: buttonAction) {

        
      VStack(spacing: 10) {

          HStack {
            Text(buttonText)
              .foregroundStyle(activeButton ? .white : Color("TextColor"))
              .font(.system(size: 18))
              .bold()
              .frame(maxWidth: isLatest ? nil : .infinity, alignment: .leading)

            if isLatest {
              Text("Latest")
                .font(.system(size: 15))
                .padding(.vertical, 4)
                .padding(.horizontal, 5)
                .background(Color("LabelBackgroundBorder"))
                .foregroundStyle(Color("BackgroundAlt"))
                .cornerRadius(5.0)
              Spacer()
            }
          }
          
          Text(buttonDescription)
            .font(.system(size: 15))
            .foregroundStyle(activeButton ? .white : Color("TextSecondary"))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 5)
        }
      .padding(.horizontal, 20)
        
        
        
    
      }
      .padding(.vertical, 20)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(activeButton ? Color("Button") : Color("BackgroundAlt"))
      .cornerRadius(5.0)
    }
    .padding(.horizontal, 20)
  }
  
  // Date Formatters
  private let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter
  }()
  
  private let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return formatter
  }()
  
  private let yearFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "YYYY"
    return formatter
  }()
}
