// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import RealmSwift

struct ServerItemViewActionsDeleteView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var item: HostDetails
    
    @State private var presentAlert : Bool = false
    
    var body: some View {
        VStack(
                alignment: .leading,
                spacing: 10
        ) {

				
            Button(action: {
                presentAlert=true
                
            }, label: {
                Text("Remove from Pocket Ops").foregroundColor(.white)
                    .font(.system(size: 15))
                    .frame(maxWidth: .infinity)
										.padding(.vertical, 15)
                    .background(Color("WarnText"))
                    .cornerRadius(5.0)
            })
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            
        }
        .padding(.bottom, 10)
        .alert("Confirm Delete", isPresented: $presentAlert, actions: { // 2
            
            // 3
            Button("Yes", role: .destructive, action: {
                
//                let realm = try! Realm()
//                try! realm.write {
//                    item.softDelete = true
//                }
                
							
                HostsDataManager.markForDeletion(item: item)
                //
                //                        validItem=false
                //                        refreshNeeded=true
                //                        serverObjects.deleteItem(item: item)
                
//							HostsDataManager().DeleteItem(item: item)
							
                dismiss()
//							DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//
//
//							}
            })
            // 3
            Button("Cancel", role: .cancel, action: {})
            
        }, message: {
            // 4
					
					if !item.isInvalidated {
						Text("Are you sure you want to remove " + item.name + " from Pocket Ops")
					}
            
        })
        
    }
}

