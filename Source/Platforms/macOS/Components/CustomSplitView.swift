// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

// Define a custom split view component
struct CustomSplitView<MenuPanel: View, RightPanel: View>: View {
  let menuPanel: MenuPanel
  let rightPanel: RightPanel
  
  init(@ViewBuilder menuPanel: () -> MenuPanel,
       @ViewBuilder rightPanel: () -> RightPanel) {
    self.menuPanel = menuPanel()
    self.rightPanel = rightPanel()
  }
  
  var body: some View {
    HStack(spacing: 0) {
      menuPanel
        .frame(minWidth: 62, idealWidth: 62, maxWidth: 62)
      rightPanel
        .frame(maxWidth: .infinity)
    }
  }
}
