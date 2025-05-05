// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

class Picker {
   
  static func highlightButton(_ highlight: Bool) -> Color {
    if highlight {
      return Color("AccentColor")
    } else {
      return .clear
    }
  }
  
  static func foregroundBar(_ highlight: Bool) -> Color {
    if highlight {
      return Color("TextColor")
    } else {
      return Color("TextSecondary")
    }
  }
  
  
  static func button(_ highlight: Bool) -> Color {
    if highlight {
      return Color("AccentColor")
    } else {
      return Color("TextSecondary")
    }
  }
  
  static func button(_ highlight: Bool, color:Color) -> Color {
    if highlight {
      return color
    } else {
      return Color("LabelBackgrounds")
    }
  }
  
  static func buttonBackground (_ highlight: Bool) -> Color {
    
    if highlight {
      return Color("Background")
    } else {
      return Color("BackgroundAlt")
    }

  }
  
  
  static func foregroundColor(_ highlight: Bool, colorScheme: ColorScheme) -> Color {
    
    if highlight {
      if colorScheme == .light {
        return .white
      } else {
        return Color("Background")
      }
    } else {
      return Color("InactiveButtonColor")
    }
  }
  
  static func foregroundColorFlipped(_ highlight: Bool, colorScheme: ColorScheme) -> Color {
    
    if highlight {
      if colorScheme == .light {
        return .white
      } else {
        return Color("Background")
      }
    } else {
      return Color("TextColor")
    }
  }
  
}

