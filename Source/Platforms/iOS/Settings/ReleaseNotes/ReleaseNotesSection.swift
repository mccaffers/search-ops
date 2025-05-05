// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct ReleaseNotesSection: View {
  
  var iconName: String
  var iconColor: Color = Color("TextColor")
  var title: String
  var detail: String
  var secondLine: String?
  var thirdLine: String?
  var textColor: Color = Color("TextSecondary")
  var showDetails: Bool
  var animationDuration: Double
  var titlePadding : CGFloat = 4
  
  var body: some View {
    VStack (spacing:10){
      HStack (spacing:0) {
        
     
        Text(title)
          .font(.system(size: 18))
          .bold()
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, titlePadding)
          .padding(.bottom, 5)
        
        Spacer()
//        
//        Image(systemName: iconName)
//          .foregroundColor(iconColor)
//          .font(.system(size: 26))
//          .frame(width: 35)
        
      }
      
      VStack(spacing: 10) {
        Text(detail)
          .lineLimit(nil)
          .frame(maxWidth: .infinity, alignment: .leading)
      
        if let secondLine = secondLine {
          Text(secondLine)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
          
        }
        
        if let thirdLine = thirdLine {
          Text(thirdLine)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
          
        }
      }
    }
    .padding(.bottom, 10)
    .opacity(showDetails ? 1 : 0)  // Start with hidden text
    .animation(.easeInOut(duration: animationDuration), value: showDetails)
  }
}
