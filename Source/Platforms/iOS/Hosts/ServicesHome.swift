// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct ServicesHome: View {
  
  @EnvironmentObject var serverObjects : HostsDataManager
  
  @State var items = [HostDetails]()
  
  
  @MainActor
  func checkForSoftDeletes() async {
    
    var deletionArray:[HostDetails] = [HostDetails]()
    
    for esItem in serverObjects.items {
      
      if !esItem.isInvalidated {
        if esItem.softDelete {
          print("one to delete")
          deletionArray.append(esItem)
        }
      }
      
    }
    
    await serverObjects.deleteItems(itemsForDeletion: deletionArray)
  }
  
  @State var navigateToAddHost : Bool = false

  var body: some View {
    
    VStack(
      alignment: .leading,
      spacing: 10
    )  {
      
      if(serverObjects.items.count == 0 || serverObjects.items.contains(where: {$0.isInvalidated})){
        
        ServiceHomeExampleView()
        Spacer()
        
      } else {
        
        if(serverObjects.items.count > 0){
          
          ScrollView {
            
            RoundedRectangle(cornerRadius: 0)
              .fill(.clear)
              .frame(height: 1)
            
            ForEach(items, id: \.self) {  index in
              //                                            Section {
              if(!index.isInvalidated){
                NavigationLink(destination: ServerItemView(item: index)) {
                  HStack {
                    VStack(
                      alignment: .leading,
                      spacing: 0
                    ){
                      
                      HStack {
                        VStack(
                          alignment: .leading,
                          spacing: 5
                        ) {
                          Text("\(index.name)")
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity, alignment:.leading)
                            .multilineTextAlignment(.leading)
                          Text("\(index.env)")
                            .font(.system(size: 15, weight: .light))
                        }
                        Spacer()
                        VStack(
                          alignment: .center,
                          spacing: 5
                        ) {
                          Text("\(index.version)")
                            .font(.system(size: 20, weight: .light))
                        }
                        
                      }.foregroundColor(.white)
                      
                      
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    
                    Spacer()
                    
                  }
                  .background(Color("Button"))
                  .cornerRadius(5)
                  .padding(.horizontal, 15)
                  
                }
                .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
        }
      }
      
    }
    .navigationTitle("Hosts")
    .navigationBarTitleDisplayMode(.large)
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          
          navigateToAddHost = true
        } label: {
          Image(systemName: "plus.app")
            .font(.system(size:24))
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onAppear {
      
      
      Task {
        await checkForSoftDeletes()
        //				serverObjects.refresh()
        items = serverObjects.items
      }
      
    }
    .onDisappear {
      items = []
    }
    .background(Color("Background"))
    .toolbarBackground(Color("TabBarColor"), for: .tabBar)
    .scrollContentBackground(.hidden)
    .navigationDestination(isPresented: $navigateToAddHost, destination: {
      AddElasticView(addServiceNavigationTitle: AddServiceNavigationTitle("New Host"))
    })
    
  }
}
#endif
