// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftUI

struct MyButtonStyle: ButtonStyle {
  
  let backgroundColor: Color?
  
  init(color:Color) {
    self.backgroundColor = color
  }
  
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .foregroundColor(configuration.isPressed ? self.backgroundColor : Color.white)
      .background(configuration.isPressed ? Color.white : self.backgroundColor)
      .cornerRadius(5.0)
  }
}


struct NiceButtonStyle: ButtonStyle {
  var foregroundColor: Color
  var backgroundColor: Color
  var pressedColor: Color

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .foregroundColor(foregroundColor)
      .background(configuration.isPressed ? pressedColor : backgroundColor)
      .cornerRadius(5)
  }
}

extension View {
  func niceButton(
    foregroundColor: Color = .white,
    backgroundColor: Color = .gray,
    pressedColor: Color = .accentColor
  ) -> some View {
    self.buttonStyle(
      NiceButtonStyle(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        pressedColor: pressedColor
      )
    )
  }
}
