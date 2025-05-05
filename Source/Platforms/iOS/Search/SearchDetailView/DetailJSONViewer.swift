// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct DetailJSONViewer: View {
    var contents: String

    
    @State private var showTextView = false
    @State var destinationView: AnyView? = nil
  
    var body: some View {
        ZStack {
            if showTextView {
              destinationView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.horizontal, 5)
            } else {
              VStack {
                ProgressView()
              }.frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(Color("Background"))
            }
        }
        .onAppear {
          destinationView = AnyView(CustomTextView(text: contents))
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showTextView = true
            }
        }
    }
}
#endif
