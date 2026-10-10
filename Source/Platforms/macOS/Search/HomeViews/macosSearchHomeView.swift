// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
struct macosSearchHomeView: View {
  
  let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
  
  @Binding var localSelectedHost: HostDetails?
  @Binding var localSelectedIndex : String
  @Binding var localSelectedDataView: DataView?
  @Binding var dataViews: [DataView]
  @ObservedObject var localFilterObject : FilterObject
  
  @Binding var indexArray : [String]
  @Binding var showing : macosSearchWelcomeScreenMainView
  
  var request : SearchRequestAction
  
  var unselectedHost : () -> ()
  
  @Binding var fields : [SquashedFieldsArray]
  
  //  @State private var loading = false
  @Binding var loadingIndices : Bool
  @Binding var loadingFieldsMapping : Bool
  
  @Binding var indexError: ResponseError?
  @State var dateView : macosDatePickerEnum = .Relative
  
  @State var searchText = ""
  var textFieldHeight : CGFloat = 38

  var updateIndexArray : () async -> ()
  var mappingRequest : () async -> ()
  var selectedHostFunc : (_ host:  HostDetails) -> ()
  @Binding var selection: macosSearchViewEnum
  @Binding var refreshDatePickers : UUID
  
  @Binding var relativeCustomdatePeriod : SearchDateTimePeriods?
  @ObservedObject var serverObjects : HostsDataManager
  @Binding var sidebar : sideBar
  @FocusState var focusedField: String?
  

  var body: some View {
    ScrollView {
      VStack(spacing:0) {
        
        Text("New Search")
          .font(.system(size: 22, weight:.light))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.bottom, 5)
        
        
        VStack(alignment: .leading, spacing:5) {
          
          macosSearchHomeHostsView(serverObjects: serverObjects,
                                   localSelectedHost: $localSelectedHost,
                                   localSelectedIndex: $localSelectedIndex,
                                   indexArray: $indexArray,
                                   localFilterObject: localFilterObject,
                                   showing: $showing,
                                   sidebar: $sidebar,
                                   selection:$selection,
                                   updateIndexArray: updateIndexArray,
                                   unselectedHost: unselectedHost,
                                   selectedHost: selectedHostFunc)
          
          if showing == .NewSearch {
            // Hidden once a plain index is picked, and back when it's cleared
            if !dataViews.isEmpty && (localSelectedIndex.isEmpty || localSelectedDataView != nil) {
              macosSearchHomeDataViewsView(dataViews: dataViews,
                                           selectedDataView: localSelectedDataView,
                                           onSelect: selectDataView,
                                           onClear: clearIndexSelection,
                                           onNew: { sidebar = .manage })
            }

              macosSearchHomeIndicesView(localSelectedHost: $localSelectedHost,
                                         localSelectedIndex: $localSelectedIndex,
                                         selectedDataView: localSelectedDataView,
                                         indexArray: $indexArray,
                                         selectedHost: $localSelectedHost,
                                         selectedIndex: $localSelectedIndex,
                                         fields:$fields,
                                         loadingIndices:$loadingIndices,
                                         indexError: $indexError,
                                         localFilterObject: localFilterObject,
                                         request: request,
                                         mappingsRequest: mappingRequest,
                                         updateIndexArray: updateIndexArray)
          
            
            
            macosSearchHomeDateTypePicker(localFilterObject: localFilterObject,
                                          selection:.constant(.None),
                                          fields: $fields,
                                          loadingFieldsMapping: $loadingFieldsMapping,
                                          dataViewTimeField: localSelectedDataView?.timeField)
            .redacted(reason: localSelectedIndex.isEmpty ? .placeholder : [])
            
            if localFilterObject.dateField != nil {
              
              VStack(alignment:.leading) {
                macosSearchHomeDateValuesAbsolute(filterObject: localFilterObject,
                                                  selection: $selection,
                                                  relativeCustomdatePeriod: $relativeCustomdatePeriod)
                .frame(maxWidth: .infinity)
                .id(refreshDatePickers)
              }
            }
            
            macosSearchHomeQueryView(searchText: $searchText, 
                                     focusedField: _focusedField,
                                     localSelectedIndex: $localSelectedIndex,
                                     localFilterObject: localFilterObject)
    
            
            HStack {
              
              macosSearchHomeSort(fields: $fields,
                                  localFilterObject: localFilterObject,
                                  selection: $selection)
              
              Spacer()
              
              Button {
                Task {
                  if let localSelectedHost = localSelectedHost {
                    request(localSelectedHost, localSelectedIndex, localFilterObject, localSelectedDataView)
                  }
                  
                }
              } label: {
                Text("Search")
                  .padding(.vertical, 10)
                  .padding(.horizontal, 20)
                  .background(Color("PositiveButton"))
                  .clipShape(.rect(cornerRadius: 5))
              }
              .buttonStyle(PlainButtonStyle())
              .disabled(localSelectedIndex.isEmpty )
              
            }
            .redacted(reason: localSelectedIndex.isEmpty ? .placeholder : [])
            Spacer()
            
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      
      }
    }
    .simultaneousGesture(TapGesture().onEnded({
      focusedField = nil
    }))
    .onChange(of: showing) { newValue in
      if newValue == .All {
        fields = []
        localSelectedHost = nil
        localSelectedIndex = ""
        localSelectedDataView = nil
        indexArray = []
        
        // Can't nil the filterObject, but must clear the internal fields
        localFilterObject.clear()
      }
    }
    .onChange(of: localSelectedIndex) { newValue in
      // Picking anything other than the view's pattern, eg. one of its indexes, leaves the data view
      localSelectedDataView = DataViewSelection.keep(localSelectedDataView, forIndex: newValue)
    }
  }

  /// Searches the view's pattern, then picks its time field once the mapping has loaded
  private func selectDataView(_ view: DataView) {
    localFilterObject.resetIndexSpecificFilters()
    withAnimation {
      localSelectedIndex = view.normalized().pattern
    }
    // Set after the index, so the index change keeps it
    localSelectedDataView = view
    Task {
      await mappingRequest()
      applyTimeField(of: view)
    }
  }

  /// As clicking the field under Date Fields would: a descending sort on it, and no time range yet
  private func applyTimeField(of view: DataView) {
    guard localSelectedDataView?.id == view.id, !view.timeField.isEmpty,
          let field = fields.first(where: { $0.squashedString == view.timeField && $0.type == "date" }) else {
      return
    }
    withAnimation {
      localFilterObject.dateField = field
      localFilterObject.sort = SortObject(order: .Descending, field: field)
    }
    localFilterObject.relativeRange = nil
    localFilterObject.absoluteRange = nil
  }

  /// Clears the data view and index, as the selected index button does
  private func clearIndexSelection() {
    withAnimation {
      localSelectedIndex = ""
      localSelectedDataView = nil
      localFilterObject.clear()
      fields = []
    }
  }
}
#endif

struct WrappingHStack: Layout {
    // inspired by: https://stackoverflow.com/a/75672314
    private var horizontalSpacing: CGFloat
    private var verticalSpacing: CGFloat
    public init(horizontalSpacing: CGFloat, verticalSpacing: CGFloat? = nil) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing ?? horizontalSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let height = subviews.map { $0.sizeThatFits(proposal).height }.max() ?? 0

        var rowWidths = [CGFloat]()
        var currentRowWidth: CGFloat = 0
        subviews.forEach { subview in
            if currentRowWidth + horizontalSpacing + subview.sizeThatFits(proposal).width >= proposal.width ?? 0 {
                rowWidths.append(currentRowWidth)
                currentRowWidth = subview.sizeThatFits(proposal).width
            } else {
                currentRowWidth += horizontalSpacing + subview.sizeThatFits(proposal).width
            }
        }
        rowWidths.append(currentRowWidth)

        let rowCount = CGFloat(rowWidths.count)
        return CGSize(width: max(rowWidths.max() ?? 0, proposal.width ?? 0), height: rowCount * height + (rowCount - 1) * verticalSpacing)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let height = subviews.map { $0.dimensions(in: proposal).height }.max() ?? 0
        guard !subviews.isEmpty else { return }
        var x = bounds.minX
        var y = height / 2 + bounds.minY
        subviews.forEach { subview in
            x += subview.dimensions(in: proposal).width / 2
            if x + subview.dimensions(in: proposal).width / 2 > bounds.maxX {
                x = bounds.minX + subview.dimensions(in: proposal).width / 2
                y += height + verticalSpacing
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .center,
                proposal: ProposedViewSize(
                    width: subview.dimensions(in: proposal).width,
                    height: subview.dimensions(in: proposal).height
                )
            )
            x += subview.dimensions(in: proposal).width / 2 + horizontalSpacing
        }
    }
}
