// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import RealmSwift

enum FocusField: Hashable {
    case field
}

enum ButtonPurpose: Hashable {
    case Test
    case Save
}

class AddServiceNavigationTitle: ObservableObject {
    @Published var name : String = ""
    
    init(_ name : String){
        self.name = name
    }
}

class ObserveFieldChanges: ObservableObject, Equatable {
    static func == (lhs: ObserveFieldChanges, rhs: ObserveFieldChanges) -> Bool {
        return lhs.change == rhs.change
    }
    
    @Published var change : String = UUID().uuidString
}

#if os(iOS)
struct AddElasticView: View {
  
  
  @EnvironmentObject var serverObjects : HostsDataManager
  
  @State var item: HostDetails = HostDetails()
  @StateObject var addServiceNavigationTitle: AddServiceNavigationTitle = AddServiceNavigationTitle("")
  @StateObject var observeFieldChanges: ObserveFieldChanges = ObserveFieldChanges()
  
  @FocusState private var focusedField: String?
  @State private var currentField: String = ""
  
  @State private var originalHeight: CGFloat? = nil
  
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) var colorScheme
  @State var ignoreSafeArea = false
  
  @State private var showTestConnection = false
  @State var customHeadersArray : [LocalHeaders] = [LocalHeaders]()
  
  @State var refresh = UUID()
  
  @State var showNavigationBar = false
  
  static func invalidContents(_ item: HostDetails) -> Bool {
    if item.cloudid.count > 0 || item.host?.url.count ?? 0 > 0 {
      return false
    }
    return true
  }
  
  static func validContentsColor(item: HostDetails, purpose: ButtonPurpose) -> Color {
    if item.cloudid.count > 0 || item.host?.url.count ?? 0 > 0 {
      if purpose == ButtonPurpose.Save {
        return Color("PositiveButton")
      } else if purpose == ButtonPurpose.Test {
        return Color("Button")
      }
    }
    return .gray
  }
  
  

  var body: some View {
    
    ZStack {
      
      ScrollView (.vertical) {
        VStack(alignment: .leading, spacing: 10) {
          
          AddHostDescriptionDetails(item: $item,
                                    focusedField: _focusedField,
                                    currentField: $currentField)
          .padding(.top, 10)
        
          HostAddDivider()
          
          ElasticConnectionDetails(item: $item,
                                   focusedField: _focusedField,
                                   currentField: $currentField)

          
          HostAddDivider()
          
          ElasticAuthenticationView(item: $item, focusedField: _focusedField, currentField: $currentField)
          
          
          HostAddDivider()
          
          CustomHeadersViews(customHeadersArray: $customHeadersArray,
                             refresh: $refresh, focusedField: _focusedField)
          
          HostAddDivider()
          
          SaveHostSectionView(customHeadersArray: $customHeadersArray,
                              item: $item,
                              showTestConnection: $showTestConnection)
          
        }
        .padding(.bottom, 10).foregroundColor(Color("TextColor"))
      }
      .scrollIndicators(.hidden)
      .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
          AddElasticKeyboardToolbarView(item: item, focusedField: _focusedField)
            .frame(maxWidth: .infinity)

        }
      }
      .onDisappear {
        //                    if !item.draft {
        //                        serverObjects.updateList(item: item, customHeaders: customHeadersArray)
        //                        serverObjects.addNew(item: item)
        //                    }
        //                    print(item.draft)
      }
      .onChange(of: observeFieldChanges.change) { newValue in
        
      }
      .onChange(of: customHeadersArray) { newValue in
        //                item.updateHeaders(newValue)
      }
      .onAppear {
        Task { @MainActor in
          customHeadersArray = item.getLocalHeaders()
          self.focusedField = currentField
          refresh=UUID()
        }
      }
      
      
    }
    .navigationDestination(isPresented: $showTestConnection) {
      TestingConnectionView(item: item)
    }
    
    .background(Color("Background"))
    
#if os(iOS)
    .navigationBarTitleDisplayMode(.large)
    
#endif
    .navigationTitle("Add a new host")
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
    .toolbar {
      NavigationLink(destination: ElasticHelpView()) {
        Text(Image(systemName: "info.square"))
          .font(.system(size: 20))
      }
    }
    .environmentObject(addServiceNavigationTitle)
    .environmentObject(observeFieldChanges)
    .onAppear {
      withAnimation(Animation.linear(duration:0)) {
        showNavigationBar = true
      }
    }
#if os(iOS)
    .toolbar(showNavigationBar ? .visible : .hidden, for:.navigationBar)
#endif
  }
  
  
}
#endif
#if os(iOS)
struct HostAddDivider : View {
  
//  let halfScreenWidth = (UIScreen.main.bounds.width / 4)*3
  var dividerColor = Color("BackgroundAlt")
  
  
  var body: some View {
    VStack {
      Rectangle()
        .fill(dividerColor)
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity)
        .frame(height: 3)
    }.frame(maxWidth: .infinity, alignment: .center)
      .padding(.vertical, 10)
      .padding(.top, 5)
  }
}
#endif
