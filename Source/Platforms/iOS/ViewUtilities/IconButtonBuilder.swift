// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

enum IconStatus: String, Hashable {
    case None = "circle.fill"
    case Checkmark = "checkmark.circle.fill"
    case Questionmark = "questionmark.circle.fill"
    case Exclamationmark = "exclamationmark.circle.fill"
}

struct IconButton: View {
  
  var systemName : String
  var status : IconStatus
  var active : Bool
  var buttonSize = CGFloat(38)
  var rotate : Angle = .degrees(0)
  var paddingBottom = CGFloat(0)
  var statusPaddingRight = CGFloat(0)
  var width = CGFloat(56)
  var iconSize = CGFloat(18)
  var height = CGFloat(45)
  
  func IconStatusColor() -> Color {
    if !active {
      return .clear
    }
    
    if status == .Checkmark {
      return .green
    } else if status == .Questionmark {
      return .orange
    } else if status == .Exclamationmark {
      return .red
    }
    
    return .clear
  }
  
  var body: some View {
    ZStack {
      
      VStack {
        Image(systemName: systemName)
          .font(.system(size: buttonSize))
          .rotationEffect(rotate)
          .padding(.bottom, paddingBottom)
      }
      
    }
  }
}
