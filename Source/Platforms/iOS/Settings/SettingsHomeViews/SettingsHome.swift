// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

public class FireworkSettings: ObservableObject {
  @Published
  var showFireworks : Bool = false
}
#if os(iOS)
struct SettingsHome: View {
  
  @AppStorage("appearanceSelection") private var appearanceSelection: Int = 2
  @ObservedObject var fireworksSettings = FireworkSettings()
  //  @State var showFireworks = false
  @State private var isVisible = false
  @State private var opacity = 1.0
  @State private var refreshFireworks = UUID()
  @State private var screenVisible = false
  @State private var myTask : Task<String, Error>? = nil
  @State private var myTaskTracker: Bool = false
  @ObservedObject var searchHistoryManager: SearchHistoryDataManager
  @ObservedObject var filterHistoryDataManager : FilterHistoryDataManager
  
  var body: some View {
    ZStack {
      NavigationStack {
        ScrollView {
          VStack (spacing:15) {
            
            SettingsActionView(searchHistoryManager: searchHistoryManager,
                               filterHistoryDataManager: filterHistoryDataManager)
            .padding(.top, 20)
            
            HostAddDivider()
            
            AppLogs()
            
            HostAddDivider()
            
            ReleaseNotesSectionView()
            
            
            HostAddDivider()
            
            AboutSearchOpsView()
            
            Feedback()
            
#if DEBUG
            HostAddDivider()
            SettingsDebugSectionView()
#endif
            
            Spacer()
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 20)
        }
        
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              
              if appearanceSelection == 2 {
                appearanceSelection=1;
              } else if appearanceSelection == 1 {
                appearanceSelection=2;
              }
              
            } label: {
              Image(systemName: appearanceSelection == 2 ? "sun.max.fill" : "moon.fill")
                .font(.system(size:24))
            }
          }
          
        }
        .background(Color("Background"))
        .frame(maxWidth: .infinity, alignment: .leading)
        .tint(Color("TextColor"))
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
        .toolbarBackground(Color("TabBarColor"), for: .tabBar)
        
      }
      .environmentObject(fireworksSettings)
      if isVisible {
        FireworksView()
          .edgesIgnoringSafeArea(.all)
          .opacity(opacity)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .edgesIgnoringSafeArea(.all)
          .ignoresSafeArea(.all)
          .isHidden(!isVisible)
          .zIndex(0)
          .id(refreshFireworks)
          .allowsHitTesting(false)
          .onDisappear {
            isVisible = false
            opacity = 1
          }
      }
    }
    .onDisappear {
      // if we leave the screen, lets stop the animation
      if myTask != nil && myTaskTracker {
        isVisible = false
        myTask?.cancel()
      }
    }
    .onChange(of: fireworksSettings.showFireworks) { newValue in
      // if a release notes page updates this to a true
      if newValue {
        isVisible = true
        opacity = 1
        refreshFireworks = UUID()
      }
      
      // Check if any existing tasks exist
      if myTask != nil && myTaskTracker {
        myTask?.cancel()
      }
      
      myTask = Task {
        // Set the booling to track the Task
        myTaskTracker = true
        
        // Set fireworks to false, so if you revisit the screen quickly this onChange will still trigger
        fireworksSettings.showFireworks = false
        
        // Delay the task by 1 second:
        try await Task.sleep(seconds: 1.5)
        
        withAnimation(.easeOut(duration: 1.5)) {
          self.opacity = 0.0
        }
        
        // Wait for the animation to finish
        try await Task.sleep(seconds: 1.5)
        
        // Hide the view
        self.isVisible = false
        
        // Update task tracking
        myTaskTracker=false
        return ""
      }
    }
  }
}
#endif
