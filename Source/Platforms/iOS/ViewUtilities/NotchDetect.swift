// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

#if os(iOS)
import Foundation
import UIKit

extension UIDevice {
  /// Returns `true` if the device has a notch
  var hasNotch: Bool {

    guard let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      return false
    }
    
    guard let firstWindow = firstScene.windows.filter({$0.isKeyWindow}).first else {
      return false
    }
    
    if UIDevice.current.orientation.isPortrait ||
        UIDevice.current.orientation == .unknown {
      return firstWindow.safeAreaInsets.top >= 44
    } else {
      return firstWindow.safeAreaInsets.left > 0 || firstWindow.safeAreaInsets.right > 0
    }
    
  }
}
#endif
