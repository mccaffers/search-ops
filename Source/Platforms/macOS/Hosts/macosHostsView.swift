// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

#if os(macOS)
struct macosHostsView: View {
  
  @State private var showingModal = false // State to control the visibility of the modal
  @State var selectedHostToEdit : HostDetails?
  @Binding var fullScreen : Bool
  
  @State var items = [HostDetails]()
 
  @ObservedObject var serverObjects : HostsDataManager
  
  @ObservedObject var hostsUpdated : HostUpdatedNotifier
  @ObservedObject var searchHistoryManager : SearchHistoryDataManager
  @Binding var selection: macosSearchViewEnum
  
  func deleteItem() async {
    items = []
    if let selectedHostToEdit = selectedHostToEdit {
      self.selectedHostToEdit = nil
      let hostID = selectedHostToEdit.id

      // attempt to delete the host
      await serverObjects.deleteItems(itemsForDeletion: [selectedHostToEdit])

      // we want to delete the history if the user deletes the host
      searchHistoryManager.deleteByHost(id: hostID)
    }
    items = serverObjects.items
    // Action to save or process the new host name
    hostsUpdated.updated = UUID()
    selection = .None
  }

  var body: some View {
    ZStack {
      VStack(alignment: .leading){
        macosHostsListView(items: $items,
                           fullScreen: $fullScreen,
                           selection: $selection,
                           selectedHostToEdit: $selectedHostToEdit)
        
      }
      .onChange(of: hostsUpdated.updated) { newValue in
        serverObjects.refresh()
        items = serverObjects.items
      }
      .onAppear {
        Task {
          items = serverObjects.items
        }
      }
      
      if selection != .None {
        RoundedRectangle(cornerRadius: 5).fill(Color.black).opacity(0.4)
          .frame(maxWidth: .infinity, alignment: .leading)
          .frame(maxHeight: .infinity)
          .contentShape(Rectangle())
          .onTapGesture {
            selection = .None
          }
          .padding(.leading, 3)
          .padding(.trailing, 5)
      }
      
      if selection == .HostManagement {
      
        macosHostAddView(selection:$selection,
                         hostsUpdated: hostsUpdated,
                         serverObjects: serverObjects,
                         item: selectedHostToEdit,
                         deleteItem: deleteItem)
        .frame(width: 600)
      }
      
    }
  }
}

#endif
