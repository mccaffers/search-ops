// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct ContentView: View {
  
  let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
    .makeConnectable()
    .autoconnect()
  
  @State var showingMain: Bool = false
  @StateObject var orientation = Orientation()
  @State var initialOrientationIsLandScape = false
  @State var loaded : Bool = false
  @State private var showingKeyUnavailable = false
  
  @AppStorage("keychainMigrationCompleted") private var keychainMigrationCompleted: Bool = false
  
  func LoadRealm() -> Bool {
    
    print("Loading Realm")
    
    if !keychainMigrationCompleted {
#if os(iOS)
      print("Preparing Realm Migration")
      let response = RealmMigration().performMigrationIfNecessary()
      print("Response from performMigrationIfNecessary()", response)
#endif
      SystemLogger().message("Migration status: \(response)")
      // A failed migration leaves the legacy key in place, so try again on the next launch
      if response.success {
        SystemLogger().message("Adding keychainMigrationComplete to userDefaults, so migration checks are ignored in the future")
        keychainMigrationCompleted = true
      }
    }
    
    let realm = RealmManager().getRealm()
    print("Realm exists: ",  realm != nil)
    return true
  }
  
  var body: some View {
    ZStack {
      Color("Background")
        .edgesIgnoringSafeArea(.all)
      
      if loaded {
        MainRoutingView()
      } else {
        ProgressView()
      }
      
    }
    .onReceive(orientationChanged, perform: { _ in
      
      if UIDevice.current.orientation == .portraitUpsideDown ||
          UIDevice.current.orientation == .faceUp ||
          UIDevice.current.orientation == .faceDown ||
          UIDevice.current.orientation == .unknown {
        return
      }
      
      orientation.orientation = UIDevice.current.orientation
      orientation.isLandscape = UIDevice.current.orientation.isLandscape
      
    })
    .onAppear {
      
      _ = LoadRealm()
      showingKeyUnavailable = RealmManager.keyUnavailable
      
      if UIDevice.current.orientation == .portraitUpsideDown ||
          UIDevice.current.orientation == .faceUp ||
          UIDevice.current.orientation == .faceDown {
        orientation.orientation = .portrait
      } else {
        orientation.orientation = UIDevice.current.orientation
      }
      
      orientation.isLandscape = UIDevice.current.orientation.isLandscape
      
      loaded=true
      
    }
    .environmentObject(orientation)
    .alert("Couldn't Load Your Data", isPresented: $showingKeyUnavailable) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("Search Ops couldn't read its encryption key from the Keychain, so your hosts and saved searches aren't loaded. Nothing has been deleted.\n\nAnything you add now won't be saved. Close Search Ops and open it again to try once more.")
    }
    
  }
  
}
#endif

