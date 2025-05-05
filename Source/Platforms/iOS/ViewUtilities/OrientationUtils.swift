// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftUI

#if os(iOS)
struct SupportedOrientationsPreferenceKey: PreferenceKey {
    static var defaultValue: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }

    static func reduce(value: inout UIInterfaceOrientationMask, nextValue: () -> UIInterfaceOrientationMask) {
        value.formIntersection(nextValue())
    }
}

class Orientation: ObservableObject {
  @Published var orientation : UIDeviceOrientation = .unknown
  @Published var isLandscape: Bool = UIDevice.current.orientation.isLandscape
}

#endif
