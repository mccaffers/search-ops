// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

enum macosHostsAddViewEnum {
  case main
  case testConnection
}

struct macosHostAddView: View {
  @Binding var selection: macosSearchViewEnum
  @ObservedObject var hostsUpdated: HostUpdatedNotifier
  @State var host = HostDetails()
  @ObservedObject var serverObjects: HostsDataManager
  
  
  var item: HostDetails? = nil
  var deleteItem: () async -> ()
  @State var showingAlert = false
  
  // Animation state
  @State private var offset: CGFloat = -500
  
  // View selection state
  @State private var currentView: macosHostsAddViewEnum = .main

  @State var isHostValid = false
  
  func handleEnterPress() {
    if let item = item {
      host.id = item.id
    }
    serverObjects.addNew(item: host)
    hostsUpdated.updated = UUID()
    selection = .None
  }
  
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Group {
          if currentView == .main {
            if item != nil {
              Text("Edit host")
            } else {
              Text("Add a new host")
            }
          } else {
            Text("Test Connection")
          }
        }
        .font(.system(size: 18))
        .bold()
        
        Spacer()
        
        if currentView == .main, let item = item, !item.isInvalidated {
          deleteButton
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 10)
      .padding(.vertical, 15)
      .background(Color("BackgroundAlt"))
      
      if currentView == .main {
        mainView
      } else {
        macosHostsTestConnectionView(currentView: $currentView,
                                     item: host)
      }
    }
    .background(Color("Background"))
    .clipShape(.rect(cornerRadius: 5))
    .offset(y: offset)
    .animation(.spring(response: 0.3, dampingFraction: 1, blendDuration: 0), value: offset)
    .onAppear {
      offset = 0  // Animate to final position
    }
    .onDisappear {
      offset = -500  // Reset for next appearance
    }
  }
  
  var deleteButton: some View {
    let message = """
              Just checking...\n
              Are you sure you want to delete \(item?.name ?? "")?\n
              This will permanently delete the record on your device. You'll need to add it again to SearchOps to search this host
              """
    
    return Button {
      showingAlert = true
    } label: {
      Text("Delete")
        .font(.system(size: 13))
        .padding(10)
        .background(Color("WarnText"))
        .clipShape(.rect(cornerRadius: 5))
    }
    .buttonStyle(PlainButtonStyle())
    .alert("", isPresented: $showingAlert, actions: {
      Button("Delete", role: .destructive) {
        Task {
          await deleteItem()
        }
      }
      Button("Cancel", role: .cancel) {}
    }, message: {
      Text(message)
    })
  }
  
  
  
  var mainView: some View {
    VStack(spacing: 10) {
      
      macosHostAddNameEnvViews(host: $host, item: item, offset:offset, isHostValid: $isHostValid)
      macosHostAddConnectionDetailsView(host: $host, item: item, offset:offset, isHostValid: $isHostValid)
      macosHostAddAuthenticationViews(host: $host, item: item, offset: offset)
      
      HStack {
        Button {
          selection = .None
        } label: {
          Text("Cancel")
            .padding(10)
            .background(Color("BackgroundAlt"))
            .clipShape(.rect(cornerRadius: 5))
        }
        .buttonStyle(PlainButtonStyle())
        
        Spacer()
        
        Button {
          withAnimation {
            currentView = .testConnection
          }
        } label: {
          Text("Test Connection")
            .padding(10)
            .background(Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isHostValid)
        
        Button {
          handleEnterPress()
        } label: {
          Group {
            if item != nil {
              Text("Update")
            } else {
              Text("Save")
            }
          }
          .padding(10)
          .background(Color("PositiveButton"))
          .clipShape(.rect(cornerRadius: 5))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isHostValid)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 10)
  }
  

}
