// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct ReleaseNotesSectionView: View {
  @State var showingReleaseNotes = false
  @EnvironmentObject var fireworkSettings : FireworkSettings
    var body: some View {
      VStack(spacing:5){

        Button(action: {
          showingReleaseNotes=true
        }, label: {
          Text("Release Notes")
            .foregroundColor(.white)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color("Button"))
            .cornerRadius(5.0)
          
        })
      }
      .navigationDestination(isPresented: $showingReleaseNotes, destination: {
        ReleaseNotesList()
      })  
    }
}
#endif
