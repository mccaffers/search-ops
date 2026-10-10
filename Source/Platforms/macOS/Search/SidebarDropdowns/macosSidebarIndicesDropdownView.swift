// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSidebarIndicesDropdownView: View {
  @Binding var selectedIndex: String
  @Binding var selectedDataView: DataView?
  @State private var indexArray = [String]()
  @State private var dataViews = [DataView]()
  @Binding var showingScreen: SideBarWrapper
  @Binding var selection: macosSearchViewEnum
  @ObservedObject var filterObject : FilterObject
  var fullScreen: Bool
  var selectedHost: HostDetails?
  
  @State private var loading = true
  @State private var indexError: ResponseError? = nil
  @Binding var firstSearchAfterSelectingIndex : Bool
  @Binding var shouldClearTextfield : Bool
  
  var request: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      macosSidebarIndicesDropdownContentView(
        loading: $loading,
        indexError: $indexError,
        selectedIndex: $selectedIndex,
        indexArray: indexArray,
        dataViews: dataViews,
        selectedDataView: selectedDataView,
        dataViewAction: selectDataView,
        searchAction: {
          // A plain index, so no data view
          selectedDataView = nil
          firstSearchAfterSelectingIndex = true
          shouldClearTextfield = true
          filterObject.resetIndexSpecificFilters()
          filterObject.clearFieldFilters()
          filterObject.query = nil
          showingScreen = SideBarWrapper(sender: .Flow, item: .Fields)
          selection = .None
          request()
        },
        hideAction: {
          selection = .None
        }
      )
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .padding(.leading, 8)
    .padding(.top, 5)
    .onAppear {
      Task {
        await updateIndexArray()
      }
    }
    .onChange(of: selectedHost?.id) { _ in
      Task {
        await updateIndexArray()
      }
    }
  }
  
  /// Searches the view's pattern by its time field, as choosing it on the home screen does
  private func selectDataView(_ view: DataView) {
    let pattern = view.normalized().pattern
    if selectedIndex == pattern && selectedDataView?.id == view.id {
      selection = .None
      return
    }
    firstSearchAfterSelectingIndex = true
    shouldClearTextfield = true
    filterObject.resetIndexSpecificFilters()
    filterObject.clearFieldFilters()
    filterObject.query = nil
    if let timeField = DataViewSelection.timeField(of: view) {
      filterObject.dateField = timeField
      filterObject.sort = SortObject(order: .Descending, field: timeField)
    }
    selectedDataView = view
    selectedIndex = pattern
    showingScreen = SideBarWrapper(sender: .Flow, item: .Fields)
    selection = .None
    request()
  }

  @MainActor
  private func updateIndexArray() async {
    do {
      guard let selectedHost = selectedHost else {
        indexError = ResponseError(title: "No Host", message: "Select a host to list indices", type: .critical)
        loading = false
        return
      }
      
      let response = await Indicies.listIndexes(serverDetails: selectedHost)
      if let parsed = response.parsed {
        let indexResult = Results.getIndexArray(parsed)
        if let error = indexResult.error {
          indexError = ResponseError(title: "Index Parsing Error", message: error, type: .critical)
        } else {
          indexArray = indexResult.data
          selectedIndex = indexArray.isEmpty ? "" : selectedIndex
          dataViews = selectedHost.isInvalidated ? [] : DataViewDataManager().views(hostId: selectedHost.id)
        }
      } else {
        indexError = ResponseError(title: "Response Error", message: "No data received", type: .critical)
      }
    }
    loading = false
  }
}

struct macosSidebarIndicesDropdownContentView: View {
  @Binding var loading: Bool
  @Binding var indexError: ResponseError?
  @Binding var selectedIndex: String
  var indexArray: [String]
  var dataViews: [DataView] = []
  var selectedDataView: DataView? = nil
  var dataViewAction: (DataView) -> Void = { _ in }
  var searchAction: () -> Void
  var hideAction: () -> ()
  
  @State private var searchText = ""
  
  var filteredIndices: [String] {
    IndexFilterHelper.filter(indices: indexArray, query: searchText)
  }

  /// Data views whose name or pattern contains the search text
  var filteredDataViews: [DataView] {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return dataViews }
    return dataViews.filter {
      $0.name.localizedCaseInsensitiveContains(trimmed) || $0.pattern.localizedCaseInsensitiveContains(trimmed)
    }
  }
  
  var showAll: Bool {
    IndexFilterHelper.showAllButton(query: searchText)
  }
  
  var totalItemCount: Int {
    filteredIndices.count + (showAll ? 1 : 0)
  }
  
  var totalListHeight: CGFloat {
    // Data view rows have two lines, and each group has a heading
    let dataViewsHeight: CGFloat = filteredDataViews.isEmpty ? 0 : CGFloat(filteredDataViews.count * 46) + 56
    if totalItemCount == 0 {
      return 60 + dataViewsHeight
    }
    return CGFloat(totalItemCount * 40) + dataViewsHeight
  }
  
  var maxPopupHeight: CGFloat {
    #if os(macOS)
    return (NSScreen.main?.visibleFrame.height ?? 800) * 0.5
    #else
    return 400
    #endif
  }
  
  var maxListHeight: CGFloat {
    max(80, maxPopupHeight - 105)
  }
  
  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 8) {
        HStack {
          Text("Indices")
            .font(.title2)
            .bold()
          Spacer()
          let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
          if !trimmed.isEmpty && !loading && indexError == nil {
            let total = IndexFilterHelper.totalCount(indices: indexArray)
            Text("\(totalItemCount) of \(total)")
              .font(.caption)
              .foregroundColor(Color("TextSecondary"))
          }
        }
        
        if !loading && indexError == nil {
          HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
              .foregroundColor(Color("TextSecondary"))
              .font(.system(size: 11))
            
            TextField("Search indices...", text: $searchText)
              .textFieldStyle(PlainTextFieldStyle())
              .font(.system(size: 13))
              .disableAutocorrection(true)
              #if os(macOS)
              .onExitCommand {
                if !searchText.isEmpty {
                  searchText = ""
                } else {
                  hideAction()
                }
              }
              #endif
            
            if !searchText.isEmpty {
              Button(action: {
                searchText = ""
              }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(Color("TextSecondary"))
                  .font(.system(size: 12))
              }
              .buttonStyle(PlainButtonStyle())
              .help("Clear search")
            }
          }
          .padding(.horizontal, 8)
          .frame(height: 28)
          .background(Color("Button"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .overlay(
            RoundedRectangle(cornerRadius: 5)
              .stroke(Color("BackgroundAlt"), lineWidth: 1)
          )
        }
      }
      .padding(.horizontal, 10)
      .padding(.top, 12)
      .padding(.bottom, 8)
      .background(Color("Background"))
      
      if loading {
        ProgressView()
          .frame(maxWidth: .infinity)
          .frame(height: 60)
      } else if let indexError = indexError {
        ErrorView(indexError: indexError)
      } else {
        macosIndiceList(
          selectedIndex: $selectedIndex,
          indexArray: filteredIndices,
          dataViews: filteredDataViews,
          selectedDataView: selectedDataView,
          dataViewAction: dataViewAction,
          showAll: showAll,
          searchAction: searchAction,
          hideAction: hideAction
        )
        .frame(height: min(totalListHeight, maxListHeight))
        .padding(.vertical, 5)
      }
    }
    .background(Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    #if os(macOS)
    .onExitCommand {
      hideAction()
    }
    #endif
  }
}

struct ErrorView: View {
    var indexError: ResponseError

    var body: some View {
        VStack(spacing: 20) {
            Text(indexError.title)
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(indexError.message)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
    }
}
