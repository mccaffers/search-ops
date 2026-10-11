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

  // nil while adding a new host
  @State var selectedHostToEdit : HostDetails?
  @Binding var fullScreen : Bool

  @ObservedObject var serverObjects : HostsDataManager

  @ObservedObject var hostsUpdated : HostUpdatedNotifier
  @ObservedObject var searchHistoryManager : SearchHistoryDataManager
  @ObservedObject var coordinator : ManageNavigationCoordinator
  @Binding var selection: macosSearchViewEnum

  func deleteHost(_ host: HostDetails) async {
    guard !host.isInvalidated else { return }
    let hostID = host.id
    selectedHostToEdit = nil
    // Back to the list first, so no screen still holds the host once it's gone
    coordinator.reset()

    // attempt to delete the host
    await serverObjects.deleteItems(itemsForDeletion: [host])

    // we want to delete the history if the user deletes the host
    searchHistoryManager.deleteByHost(id: hostID)
    DataViewDataManager().deleteByHost(id: hostID)
    SavedDocumentDataManager().deleteByHost(id: hostID)
    SavedSearchDataManager().deleteByHost(id: hostID)

    hostsUpdated.updated = UUID()
    selection = .None
  }

  var body: some View {
    ZStack {
      macosManageHostsView(fullScreen: $fullScreen,
                           serverObjects: serverObjects,
                           hostsUpdated: hostsUpdated,
                           coordinator: coordinator,
                           selection: selection,
                           onAddHost: {
                             selectedHostToEdit = nil
                             selection = .HostManagement
                           },
                           onEditHost: { host in
                             selectedHostToEdit = host
                             selection = .HostManagement
                           },
                           onDeleteHost: { host in
                             Task {
                               await deleteHost(host)
                             }
                           })

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
                         item: selectedHostToEdit)
        .frame(maxWidth: 600)
      }

    }
  }
}

#endif
