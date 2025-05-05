// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import RealmSwift

#if os(iOS)
struct SaveHostSectionView: View {
  
  @EnvironmentObject var serverObjects : HostsDataManager
  
  // Environment Objects
  @Environment(\.dismiss) private var dismiss
  
  @Binding var customHeadersArray : [LocalHeaders]
  @Binding var item: HostDetails
  @State private var showingAlert = false
  
  @Binding var showTestConnection : Bool
  
  @EnvironmentObject var observeFieldChanges: ObserveFieldChanges
  
  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 10
    )  {
      
      AddHostHeaderLabel(title:"Test & Save")
      
      VStack (spacing:10) {
        Button(action: {
          showTestConnection=true
        }, label: {
          Text("Test")
            .font(.system(size: 15))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height:40)
            .background(AddElasticView.validContentsColor(item: item, purpose: ButtonPurpose.Test))
            .cornerRadius(5.0)
          
        })
        .disabled(AddElasticView.invalidContents(item))
        .id(observeFieldChanges.change)
        
        Button(action: {
          if item.isValid() {
            
            if !item.draft {
              //                        let realm = try! Realm()
              //                        try! realm.write {
              //                            // we create a shallow copy of the realm obj
              //                            // so that it isn't updated as the user makes changes
              //                            // as they might leave the app or view without wanting to save
              //                            // so we update the id when they hit save
              //                            item.id = item.detachedID
              //                        }
              
              HostsDataManager.detachFromSync(item: item)
              
            } else {
              //                        let realm = try! Realm()
              //                        try! realm.write {
              //                            item.draft = false
              //                        }
              HostsDataManager.saveItem(item: item)
            }
            
            HostsDataManager.removeTrailingSlash(item:item)
            
            // TODO: Not sure if needed
            serverObjects.updateList(item: item, customHeaders: customHeadersArray)
            serverObjects.addNew(item: item)
            dismiss()
          } else {
            showingAlert = true
            print("missing a field")
          }
          
        }) {
          Text(item.draft ? "Save" : "Update")
            .font(.system(size: 15))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height:40)
            .background(AddElasticView.validContentsColor(item: item, purpose: ButtonPurpose.Save))
            .cornerRadius(5.0)
        }
        .disabled(AddElasticView.invalidContents(item))
        .alert("Missing input", isPresented: $showingAlert) {
          Button("Okay", role: .cancel) { }
        }
        .onChange(of: item) { newValue in
          print("changed")
        }
        .id(observeFieldChanges.change)
      }
      .padding(.horizontal, 20)
      
    }
    .padding(.bottom, 10)
  }
}
#endif
