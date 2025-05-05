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
    
    VStack {
      
      
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
      .padding(.leading, 10)
      .padding(.top, 10)
      //            .padding(.top, selectedHost == nil ? 55 : 70)
      //            .shadow(color: Color("Background"), radius:5, x: 0, y: 0)
      
      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onAppear {
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
  
  var totalSize : CGFloat {
    
    var totalCount = indexArray.count + 1
    var height = 40
    
    return CGFloat(totalCount * height)
  }
  var body: some View {
    VStack (spacing:0 ){
      Text("Indices")
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.title2)
        .padding(.leading, 10)
        .padding(.top, 15)
        .padding(.bottom, 10)
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
          indexArray: indexArray,
          searchAction: searchAction,
          hideAction: hideAction
        )
        .frame(height: totalSize)
        .padding(.vertical, 5)
      }
    }
    .background(Color("Button"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
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
