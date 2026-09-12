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
  @State private var indexArray = [String]()
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
        searchAction: {
          Task {
            firstSearchAfterSelectingIndex = true
            shouldClearTextfield = true
            request()
            showingScreen = SideBarWrapper(sender: .Flow, item: .Fields)
            filterObject.dateField = nil
            selection = .None
          }
        },
        hideAction: {
          selection = .None
        }
      )
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .padding(.leading, 10)
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
  var searchAction: () -> Void
  var hideAction: () -> ()
  
  @State private var searchText = ""
  
  var filteredIndices: [String] {
    IndexFilterHelper.filter(indices: indexArray, query: searchText)
  }
  
  var showAll: Bool {
    IndexFilterHelper.showAllButton(query: searchText)
  }
  
  var totalItemCount: Int {
    filteredIndices.count + (showAll ? 1 : 0)
  }
  
  var totalListHeight: CGFloat {
    if totalItemCount == 0 {
      return 60
    }
    return CGFloat(totalItemCount * 40)
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
