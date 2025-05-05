// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct ClearBackgroundView: UIViewRepresentable {
    
    @AppStorage("appearanceSelection") private var appearanceSelection: Int = 2
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView()
            
        var colorScheme : UIUserInterfaceStyle
        
        if appearanceSelection == 1 {
            colorScheme = .light
        }
        else if appearanceSelection == 2 {
            colorScheme = .dark
        } else {
            colorScheme = UIScreen.main.traitCollection.userInterfaceStyle
        }
        
        let color = Color(UIColor(named: "Background")!.resolvedColor(with: UITraitCollection(userInterfaceStyle: colorScheme)))
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = UIColor(color)
        }
        return view
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}

struct ClearBackgroundViewModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .background(ClearBackgroundView())
    }
}

extension View {
    func clearModalBackground()->some View {
        self.modifier(ClearBackgroundViewModifier())
    }
}
#endif
