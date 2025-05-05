// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct ReleaseNotesModalView: View {
  
  @Environment(\.openURL) var openURL
  @Environment(\.dismiss) var dismiss
  
  @EnvironmentObject var orientation : Orientation

  var body: some View {
    VStack (spacing:0) {
      
      VStack{
        VStack {
          HStack {
            HStack(spacing:8) {
              Image(systemName: "note.text")
                .fontWeight(.medium)
              Text("Release Notes")
                .font(.system(size: 20))
            }
            Spacer()
            
            if orientation.orientation == .landscapeLeft ||
                orientation.orientation == .landscapeRight {
              Button {
                dismiss()
              } label: {
                Text("Close")
                  .padding(10)
              }
            }
          }
          .frame(maxWidth: .infinity, alignment:.leading)
        }.padding(.horizontal, 15)
      }
      .padding(.vertical, 20)
      .background(Color("Button"))
      .padding(.bottom, 20)
      
      VStack(spacing:20) {
        
        Text("Release notes and screenshots of new features are available to view at searchops.app")
          .frame(maxWidth: .infinity, alignment:.leading)
        
        VStack (spacing:5){
          Button {
            openURL(URL(string: "https://searchops.app/release-notes/")!)
          } label: {
            HStack {
              Image(systemName: "link")
              Text("View Release Notes")
            }
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(Color("Button"))
            .cornerRadius(5)
          }
          Text("Opens an external link to https://SearchOps.app")
            .font(.system(size: 14))
            .foregroundColor(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment:.center)
        }
      }
      .padding(.horizontal, 15)
      
      
      Spacer()
      
    }.background(Color("Background"))
  }
}
#endif
