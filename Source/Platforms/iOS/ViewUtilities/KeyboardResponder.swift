// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

final class KeyboardResponder: ObservableObject {
    private var notificationCenter: NotificationCenter
    @Published private(set) var willHide: String = ""
    @Published private(set) var willShow: String = ""
    
    init(center: NotificationCenter = .default) {
        notificationCenter = center
#if os(iOS)
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
      #endif
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
    
    @MainActor
    @objc func keyBoardWillShow(notification: Notification) {
        
        // TODO
        // Publishing changes from within view updates is not allowed, this will cause undefined behavior.
        self.willShow = UUID().uuidString
    }

    @MainActor
    @objc func keyBoardWillHide(notification: Notification) {
        self.willHide = UUID().uuidString
    }
}


#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
