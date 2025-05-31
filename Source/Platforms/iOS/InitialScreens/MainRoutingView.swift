// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

#if os(iOS)
import SwiftUI

struct MainRoutingView: View {
  
  @AppStorage("showInitialScreen") private var showInitialScreen: Bool = true
  @AppStorage("lastSeenVersionNotes") private var lastSeenVersionNotes: String = ""
  
  private enum VersionSheetEnum : String, Identifiable {
    case Version1_94
    case Version2_0
    case Version3_0
    public var id: String { rawValue }
  }

  @State private var versionSheet : VersionSheetEnum?
  @State private var showingVersionSheet = false
  var body: some View {
    VStack {
      if showInitialScreen {
        Welcome()
      } else {
        Navigation()
          .redacted(reason: showingVersionSheet ? .placeholder : [])
          .disabled(showingVersionSheet)
      }
    }.onAppear {
      
      if  "3.0" != lastSeenVersionNotes {
        showingVersionSheet = true
      }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        if "3.0" != lastSeenVersionNotes {
          versionSheet = .Version3_0
        }
      }
      
//      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//        lastSeenVersionNotes = "0"
//      }
      
      
    }
    .sheet(item: $versionSheet,
           content: { sheet in
      switch sheet {
        
      case .Version1_94:
        Version_1_94(showContinueButton:true,
                     lastSeenVersionNotes:$lastSeenVersionNotes)
      
      case .Version2_0:
        Version_2_0(showContinueButton:true)
          .onDisappear {
          
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
              lastSeenVersionNotes = "2.0"
            }
            
            withAnimation {
              showingVersionSheet = false
            }
          }
        
      case .Version3_0:
        Version_3_0(showContinueButton:true)
          .onDisappear {
  
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
              lastSeenVersionNotes = "3.0"
            }
            
            withAnimation {
              showingVersionSheet = false
            }
          }
      }
    })
    
    
  }
}
#endif
