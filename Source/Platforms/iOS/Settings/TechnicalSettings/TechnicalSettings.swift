// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct TechnicalSettings: View {
  
  @AppStorage("lastSeenVersionNotes") private var lastSeenVersionNotes: String = ""
  @AppStorage("keychainMigrationCompleted") private var keychainMigrationCompleted: Bool = false
  
  @MainActor func debug() throws {
    RealmManager().clearRealmInstance()
    try KeychainManager().delete()
    _=LegacyKeychainManager().deleteLegacyKeychain()
    
    keychainMigrationCompleted=false
    lastSeenVersionNotes=""
    
    
    Task { @MainActor in
      keychainMigrationCompleted=false
      lastSeenVersionNotes=""
      
    }
    
  }
  
  var body: some View {
    VStack {
      
      Text("You should never need to, but you can delete the entire Realm Database and start fresh. ")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 10)
      
      Text("This will delete the Realm Database on disk, and the encrypted key in the keychain. This is non-reversable. A new blank realm database and new encryption key will be generated so you can continue to use the application.")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 10)
      
      Button(action: {
        try! debug()
      }, label: {
        Text("Delete Realm Database")
          .foregroundColor(.white)
          .padding(.vertical, 15)
          .frame(maxWidth: .infinity, alignment: .center)
          .background(Color("WarnText"))
          .cornerRadius(5.0)
        
      })
<<<<<<< HEAD
      
=======

>>>>>>> main
      Spacer()
      
    }
    .padding(.horizontal, 20)
    .navigationTitle("Database Settings")
    .toolbarBackground(Color.pink,
<<<<<<< HEAD
                       for: .navigationBar)
    
    .frame(maxWidth: .infinity)
    .background(Color("Background"))
    
=======
                 for: .navigationBar)
         
    .frame(maxWidth: .infinity)
    .background(Color("Background"))

>>>>>>> main
  }
}

#Preview {
    TechnicalSettings()
}
#endif
