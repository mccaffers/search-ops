// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import OrderedCollections

struct macosSearchResultsView: View {
  @Binding var renderedObjects: RenderObject?
  @ObservedObject var viewableFields: RenderedFields
  
  var fields : [SquashedFieldsArray]
  /// Changes each time a field is picked or hidden, as the fields are classes whose `visible` changes in place.
  var fieldsVersion: UUID
  var showDateHeader: Bool
  /// The data view's field labels, for the table headers
  var labels: [String: String] = [:]
  @Binding var columnWidths: [macosTableColumn: CGFloat]
  var onHideField: (macosTableColumn) -> Void = { _ in }
  var onOpenDocument: (OrderedDictionary<String, Any>, DocumentRef?) -> Void
  /// Filters the search for a field's value, or against it when negated, from the table's cells
  var onFilter: ((_ field: String, _ value: String, _ negated: Bool) -> Void)? = nil
  /// How many field filters are on, so an empty search can point at them
  var activeFilterCount: Int = 0
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
            
            HStack(spacing: 10) {
              Button {
                searchResponseError = nil
              } label: {
                Text("Dismiss")
                  .padding(8)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
                  .contentShape(Rectangle())
              }
              .buttonStyle(PlainButtonStyle())
              
              Button {
                Request(currentPage > 0 ? currentPage : 1)
              } label: {
                Text("Retry")
                  .padding(8)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
                  .contentShape(Rectangle())
              }
              .buttonStyle(PlainButtonStyle())
              
              Spacer()
            }
            
            Spacer()
          }.frame(maxWidth: 500)
            .padding(.top, 20)
          Spacer()
        }
        
      } else if searchIndicator && renderedObjects == nil {
        VStack {
          ProgressView().scaleEffect(1.2)
            .padding(.top, 40)
          Spacer()
        }
      } else if renderedObjects == nil || renderedObjects?.results.count == 0 {
        VStack {
          Text(Self.noResultsMessage(activeFilterCount: activeFilterCount))
            .padding(.top, 30)
          Spacer()
        }
        
      } else {
        
        VStack {
          
          macosTableSearchView(renderedObjects: $renderedObjects,
                               resultsFields: viewableFields,
                               itemDetail: itemDetail,
                               filteredFields: fields,
                               fieldsVersion: fieldsVersion,
                               showDateHeader: showDateHeader,
                               labels: labels,
                               setWidths: $columnWidths,
                               onHideField: onHideField,
                               onOpenDocument: onOpenDocument,
                               onFilter: onFilter)
          
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

extension macosSearchResultsView {
  /// What to try when a search finds nothing. Filters that are on come first, as each one can rule out
  /// every document by itself.
  static func noResultsMessage(activeFilterCount: Int) -> String {
    if activeFilterCount > 0 {
      let filters = activeFilterCount == 1 ? "the filter" : "a filter"
      return "No results. Try disabling or removing \(filters), or adjusting the query string or date range."
    }
    return "No results. Try adjusting the query string or date range."
  }
}
