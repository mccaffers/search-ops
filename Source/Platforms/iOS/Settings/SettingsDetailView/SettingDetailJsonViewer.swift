// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SettingDetailJsonViewer: View {
  
  var text : String
  
  var body: some View {
    VStack(alignment: .leading){
      Text(verbatim: text)
        .frame(maxWidth: .infinity, alignment:.leading)
        .textSelection(.enabled)
    }.frame(maxWidth: .infinity, alignment:.leading)
  }
  
}

#if os(iOS)
class TiledLabel: UILabel {
  override class var layerClass: AnyClass {
    return CATiledLayer.self
  }
}
#endif
