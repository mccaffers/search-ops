// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct ReducingBarView: View {
  @State private var barWidth: CGFloat
  @State private var timer: Timer?
  
  // You can pass the initial width and action from the parent view
  var initialWidth: CGFloat
  var actionWhenFinished: () -> Void
  
  init(initialWidth: CGFloat, actionWhenFinished: @escaping () -> Void) {
    self.initialWidth = initialWidth
    self.actionWhenFinished = actionWhenFinished
    _barWidth = State(initialValue: initialWidth)
  }
  
  var body: some View {
    VStack {
      if barWidth > 0 {
        Rectangle()
          .fill(Color.red)
          .frame(width: barWidth, height: 5)
          .onAppear {
            // Delay the timer start immediately onAppear
            DispatchQueue.main.async {
              self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if self.barWidth > 0 {
                  self.barWidth -= 3
                } else {
                  self.timer?.invalidate()
                  self.actionWhenFinished()
                }
              }
            }
          }
          .animation(.linear, value: barWidth) // Animate the change in width
      } else {
        Rectangle()
          .fill(Color.clear)
          .frame(maxWidth: .infinity)
          .frame(height: 5)
        
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onDisappear {
      timer?.invalidate()
    }
    .onAppear {
      barWidth = initialWidth
    }
    
  }
}
