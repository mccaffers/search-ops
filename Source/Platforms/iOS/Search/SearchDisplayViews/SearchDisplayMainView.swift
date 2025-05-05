// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct SearchDisplayMainView: View {
  
  @EnvironmentObject var selectedHost: HostDetailsWrap
  
  var validSearchResults : Bool
  var showingGrid : Bool
  
  @Binding var searchResults : [[String: Any]]?
  @ObservedObject var viewableFields: RenderedFields
  @Binding var updatedFieldsNotification : UUID
  @Binding var renderedObjects : RenderObject?
  @Binding var filteredFields : [SquashedFieldsArray]
  @ObservedObject var itemDetail : DocumentDetail
  @Binding var showingAllButtons : Bool

  @Binding var loading: Bool
  var hitCount : Int
  @Binding var page : Int
  var pageCount : Int
  
  @Binding var hideNavigation : Bool
  @Binding var hidePagination : Bool
  @Binding var hideBottomBar : Bool
  @Binding var postRequestUpdate: UUID
  
  @State var initComplete = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      
      if validSearchResults {
        
        ZStack {
          
          if showingGrid {
            SearchResultsView(
              resultsFields: viewableFields,
              updatedFieldsNotification: $updatedFieldsNotification,
              renderedObjects: $renderedObjects,
              filteredFields: $filteredFields,
              itemDetail: itemDetail)
            
          } else {
            
            SimpleSearchResultsView(renderedObjects: $renderedObjects,
                                    resultsFields: viewableFields,
                                    itemDetail: itemDetail,
                                    filteredFields: $filteredFields)
          }
          
          
          VStack {
            Spacer()
            HStack {
              Spacer()
              
              
              Text(Image(systemName: showingAllButtons ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left"))
                .font(.system(size:22))
                .scaleEffect(CGSize(width: -1.0, height: 1.0))
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .foregroundColor(.white)
                .background(Color("Button"))
#if os(iOS)
                .cornerRadius(5, corners: [.topLeft])
#endif
                .onTapGesture {
                  showingAllButtons.toggle()
                }
              
            }
          }.offset(y:hidePagination ? 100 : 0)
          
          
        }.onAppear {
          
          if hidePagination {
            
            // if the itemDetail.item is populated,
            // it means the detail view has been viewed
            // on return we need to delay the pagination bar appearing
            // or it jumps at the same time as the tab bar
            // so we add 0.7 seconds
            let addTime = (itemDetail.item?.count ?? 0) > 0 ? 0.7 : 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + (0.3+addTime)) {
              withAnimation( Animation.linear(duration: 0.5)) {
                hidePagination = false
              }
              withAnimation( Animation.linear(duration: 0.2)) {
                hideBottomBar = false
              }
            }
          }
          
        }
        
      }
      else {
        ZStack {
          
          ResultsPlaceholderView(loading:$loading,
                                 initComplete:$initComplete)
          .disabled(true)
          
          if searchResults?.count ?? 0 > 0 {
            
            VStack {
              Spacer()
              HStack {
                Spacer()
                
                
                Text(Image(systemName: showingAllButtons ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left"))
                  .font(.system(size:22))
                  .scaleEffect(CGSize(width: -1.0, height: 1.0))
                  .padding(.horizontal, 10)
                  .padding(.vertical, 10)
                  .foregroundColor(.white)
                  .background(Color("Button"))
#if os(iOS)
                  .cornerRadius(5, corners: [.topLeft])
#endif
                  .onTapGesture {
                    showingAllButtons.toggle()
                  }
                
                
              }
            }
            .offset(y:hidePagination ? 100 : 0)
          }
          
          if searchResults?.count == 0 {
            VStack(spacing:10) {
              
              Text(Image(systemName: "exclamationmark.icloud.fill"))
              
                .font(.system(size: 36))
              
              Text("0 documents found")
                .font(.system(size: 18))
              
            }
          }
          
        }
#if os(iOS)
        .toolbar(!showingAllButtons ? .hidden : .visible, for: .tabBar)
#endif
        
      }
      
      
      SearchResultsActionsView(
        showingAllButtons: $showingAllButtons,
        hitCount: hitCount,
        postRequestUpdate: $postRequestUpdate, page: $page,
        pageCount : pageCount)
      
      .offset(y:hideBottomBar ? 100 : 0)
      .frame(height: hideBottomBar ? 0 : nil)
      
    }
    .onChange(of: showingAllButtons) { newValue in
      if !showingAllButtons {
        hideNavigation=true
      } else {
        hideNavigation=false
      }
    }
    .onChange(of: loading) { newValue in
      //
    }
    .onChange(of: updatedFieldsNotification) { newValue in
      renderedObjects = Results.UpdateResults(searchResults: searchResults,
                                              resultsFields: viewableFields)
      
      
    }
    .onChange(of: selectedHost.item){ newValue in
      
      if newValue == nil && renderedObjects != nil {
        renderedObjects = nil
      }
    }
    
  }
}
#endif
