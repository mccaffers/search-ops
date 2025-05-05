// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

class ButtonColor {
    
    static func Background (_ item: Any?) -> Color {
        if item == nil {
            return Color("InactiveButtonBackground")
        } else {
            return Color("Button")
        }
    }
    
    static func BackgroundAccent (_ item: Any?) -> Color {
        if item == nil {
            return Color("InactiveButtonBackground")
        } else {
            return Color("AccentColor")
        }
    }
    
    static func TextColorOutSideButton (_ item: Any?) -> Color {
        if item == nil {
            return Color("InactiveButtonBackground")
        } else {
            return Color("TextColor")
        }
    }
    
    static func Text(_ item: Any?) -> Color {
        if item == nil {
            return Color("Background")
        } else {
            return .white
        }
    }
    
    static func Text(_ item: Any?, inputColor: Color) -> Color {
        if item == nil {
            return Color("InactiveButtonText")
        } else {
            return inputColor
        }
    }
    
}
