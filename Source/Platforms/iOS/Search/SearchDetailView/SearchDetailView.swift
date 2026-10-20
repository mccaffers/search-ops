// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import OrderedCollections
import SwiftyJSON

#if os(iOS)
enum DocumentDetailState: Hashable {
    case JSON
    case Fields
}

struct SearchDetailView: View {
  
  @ObservedObject var itemDetail : DocumentDetail
  @State var selection : DocumentDetailState = DocumentDetailState.Fields
  @Binding var presentedSheet: SearchSheet?
  @Binding var fields : [SquashedFieldsArray]
  @Binding var showDateInputView: DateQuery?
  /// The host and what was searched when the document was found, to save it with
  var host: HostDetails?
  var searchIndex: String

  @EnvironmentObject var filterObject: FilterObject
  @State private var isSaved = false
  @State private var saveError: String? = nil
  
  func returnJson (input:OrderedDictionary<String, Any>) -> String {
    
    var myDic = Dictionary<String, Any>()
    for item in input {
      
      myDic.updateValue(item.value, forKey: item.key)
    }
    
    let jsonString = JSON(myDic).rawString(options:[.sortedKeys, .withoutEscapingSlashes, .prettyPrinted]) ?? ""
    return jsonString
    
  }
  
  @State var contents : String = ""
  @State var toolbarButtonString : String = "JSON"
  @State var navigationBarTitle : String = "Document"

#if os(iOS)
  @State var navigationTitleSize : NavigationBarItem.TitleDisplayMode = .large
#endif

  var body: some View {
    Group {
      if selection == .JSON {
        DetailJSONViewer(contents:contents.prettifyJSON())
      } else {
        ScrollView {
          VStack(spacing:0) {
            //            DetailViewPicker(selection: $selection)
            //                .padding(.bottom, selection == .Fields ? 10 : 0)
            //
            if selection == .Fields {
              DetailFieldsView(itemDetail: itemDetail,
                               presentedSheet: $presentedSheet,
                               fields: fields,
                               showDateInputView:$showDateInputView)
              
            }
          }
        }
      }
    }
    .background(Color("Background"))
    .onAppear {
      if let item = itemDetail.item {
        contents = returnJson(input: item).trimmingCharacters(in: .whitespacesAndNewlines)
      }
      refreshSaved()
    }
    .alert("Couldn't Save", isPresented: Binding(
      get: { saveError != nil },
      set: { if !$0 { saveError = nil } }
    )) {
      Button("OK", role: .cancel) { }
    } message: {
      Text(saveError ?? "")
    }
    .onDisappear {
      //            itemDetail.item = nil
      itemDetail.showingView = false
    }
#if os(iOS)
    .toolbar {
      if canSave {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: toggleSaved) {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
          }
          .tint(Color("AccentColor"))
          .accessibilityLabel(isSaved ? "Remove from Saved" : "Save Document")
        }
      }
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(toolbarButtonString) {
          if selection == .Fields {
            selection = .JSON
            navigationTitleSize = .inline
            toolbarButtonString="Document"
            navigationBarTitle="JSON Object"
          } else {
            selection = .Fields
            navigationTitleSize = .large
            toolbarButtonString="JSON"
            navigationBarTitle="Document"
          }
        }
        .tint(Color("AccentColor"))
        .foregroundColor(Color("TextColor"))
      }
    }

    .navigationBarBackgroundVisibleBeforeiOS26()
    .navigationTitle(navigationBarTitle)
    .toolbarBackground(Color("TabBarColor"), for: .navigationBar)
    .navigationBarTitleDisplayMode(navigationTitleSize)
    #endif
  }

  private var hostId: UUID? {
    guard let host = host, !host.isInvalidated else { return nil }
    return host.id
  }

  /// Only a document whose index and id are known can be found again
  private var canSave: Bool {
    hostId != nil && itemDetail.ref != nil
  }

  private func refreshSaved() {
    guard let hostId = hostId, let ref = itemDetail.ref else {
      isSaved = false
      return
    }
    isSaved = SavedDocumentDataManager().find(hostId: hostId, ref: ref) != nil
  }

  /// Saves the document with the search it was found in, its period pinned to the dates it covers now, or unsaves it
  private func toggleSaved() {
    guard let hostId = hostId, let ref = itemDetail.ref else { return }
    let manager = SavedDocumentDataManager()
    if isSaved {
      manager.delete(hostId: hostId, ref: ref)
      isSaved = false
      return
    }
    let document = SavedDocument.make(hostId: hostId,
                                      ref: ref,
                                      searchIndex: searchIndex.trimmingCharacters(in: .whitespacesAndNewlines),
                                      dataView: nil,
                                      dateField: filterObject.dateField,
                                      dateRange: filterObject.snapshotDateRange())
    do {
      try manager.save(document)
      isSaved = true
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    } catch {
      saveError = (error as? SavedDocumentError)?.message ?? error.localizedDescription
    }
  }
}
#endif
