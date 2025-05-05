// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchResultsView: View {
  @Binding var renderedObjects: RenderObject?
  @ObservedObject var viewableFields: RenderedFields
  @EnvironmentObject var filterObject: FilterObject
  
  var fields : [SquashedFieldsArray]
  @Binding var selectedHost: HostDetails?
  @Binding var selectedIndex: String
  @State var loadingFields : String = ""
  
  @ObservedObject var itemDetail : DocumentDetail
  
  @Binding var searchResultsUpdated : UUID
  
  @Binding var currentPage : Int
  @Binding var pageCount : Int
  @Binding var searchResponseError : ResponseError?
  
  var searchIndicator : Bool
  
  var Request : (_ input:Int) -> ()
  
  var body: some View {
    HStack (spacing:5) {
      
      if let error = searchResponseError {
        HStack {
          Spacer()
          VStack(spacing:15) {
            Image(systemName: "exclamationmark.triangle")
              .font(.system(size: 50))
              .foregroundStyle(Color.red)
            Text(error.title)
              .font(.system(size: 18))
              .frame(maxWidth: .infinity, alignment: .leading)
            Text(error.message)
              .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
          }.frame(maxWidth: 500)
            .padding(.top, 20)
          Spacer()
        }
        
      } else if renderedObjects == nil {
        VStack {
          ProgressView().scaleEffect(1.2)
            .padding(.top, 40)
          Spacer()
        }
      }  else if renderedObjects?.results.count == 0 {
        VStack {
          Text("No results. Try adjusting the query string or date range.")
            .padding(.top, 30)
          Spacer()
        }
        
      } else {
        
        VStack {
          
          macOSDocumentSearchView(renderedObjects: $renderedObjects,
                                  resultsFields: viewableFields,
                                  itemDetail: itemDetail,
                                  filteredFields: fields)
          
          
          if searchIndicator {
            HStack {
              Spacer()
              ProgressView().scaleEffect(0.5)
                .padding(.top, -5)
              Spacer()
            }.frame(maxHeight: 30)
          } else {
            HStack {
              Button {
                Request(1)
              } label: {
                Image(systemName: "chevron.left.2")
                  .padding(10)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
                  .contentShape(Rectangle())
              }
              .buttonStyle(PlainButtonStyle())
              .disabled(currentPage == 1)
              
              Button {
                Request(currentPage-1)
              } label: {
                Image(systemName: "chevron.left")
                  .padding(10)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
                  .contentShape(Rectangle())
              }
              .buttonStyle(PlainButtonStyle())
              .disabled(currentPage == 1)
              
              Text("Page " + currentPage.string + " of " + pageCount.string)
              
              
              Button {
                Request(currentPage+1)
              } label: {
                Image(systemName: "chevron.right")
                  .padding(10)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
                  .contentShape(Rectangle())
              }
              .buttonStyle(PlainButtonStyle())
              .disabled(currentPage == pageCount)
              
            }
            
          }
        }
      }
    }
    
  }
}
