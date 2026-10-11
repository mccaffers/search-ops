// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI
import OrderedCollections

#if os(macOS)

struct macosSearchMainView: View {
  @Binding var macosSearchRouterPath : macosSearchRouterPath
  @ObservedObject var serverObjects: HostsDataManager
  @State private var searchText = ""
  @Binding var selectedHost: HostDetails?
  @Binding var selectedIndex: String
  // Set while searching a data view's pattern, for its name and labels
  @Binding var selectedDataView: DataView?
  /// Columns from a saved search, shown once its first search has loaded the fields
  @Binding var pendingSelectedFields: [String]?
  /// Column widths from a saved search, set with its columns
  @Binding var pendingColumnWidths: [String: Double]?
  /// The saved search this search came from, so saving again can update it
  @Binding var savedSearchLink: SavedSearchLink?
  
  @StateObject var resultsFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
  @State var renderedObjects: RenderObject?
  @State var filteredFields = [SquashedFieldsArray]()
  @ObservedObject var filterObject : FilterObject
  @Binding var selection: macosSearchViewEnum
  @State var viewableFields: RenderedFields = RenderedFields(fields: [])
  
  @State var fields = [SquashedFieldsArray]()
  @State var onlyVisibleFields = [SquashedFieldsArray]()
  @State private var fieldsCacheKey: String = ""
  @State private var currentActiveDateField: String? = nil
  /// The order the user dragged the selected fields into, used for the table columns. Reset per host and index.
  @State private var selectedFieldOrder = [String]()
  /// Table column widths set by dragging a column border or double-clicking one. Reset per host and index.
  @State private var tableColumnWidths = [macosTableColumn: CGFloat]()
  
  @State var updatedFieldsNotification : UUID = UUID()

  // detailed item view
  @StateObject var itemDetail : DocumentDetail = DocumentDetail()
  /// Whether the document open in the panel is in the Saved tab
  @State private var isDocumentSaved = false
  @State private var showingSavePopover = false
  /// eg. "Saved" or "Updated", shown on the Save button for a moment afterwards
  @State private var saveConfirmation: String? = nil
  @State var searchResultsUpdated : UUID = UUID()
  @FocusState var focusedField: String?
  @State var items = [HostDetails]()
  
  @State var showingModal : Bool = false // State to control the visibility of the modal
  @State var selectedHostToEdit : HostDetails?
  @EnvironmentObject var hostsUpdated : HostUpdatedNotifier
 
  @State var selected = false
  @State var topBarDateButtonRefresh = UUID()
  @Binding var fullScreen : Bool
  
  @State var showingScreen : SideBarWrapper = SideBarWrapper(item: .Hosts)

  @State var searchIndicator : Bool = false
  
  @State var firstSearchAfterSelectingIndex = false
  @State var shouldClearTextfield = false
  @State var lastValue = ""
  
  @State var currentPage = 0
  @State var pageCount = 1
  
  @State private var timeElapsed = 0
  @State private var timer: Timer?
  @State private var schedule: TimerInterval?
  @State private var dateRangeWhenPickerOpened: String?
  
  @State var searchResponseError : ResponseError?
  /// Round-trip time of the latest search, kept on screen while the next one runs. Cleared per host and index.
  @State private var lastLatency: Duration?
  /// Documents matching the last successful search, and whether the server stopped counting there
  @State private var lastHitCount: (count: Int, isLowerBound: Bool)?

  /// Document counts over the time period, from the last first-page search
  @State var histogram : SearchHistogram?
  /// Time periods from before each zoom into the histogram, the last one is restored first
  @State var zoomHistory = [DateRangeSnapshot]()
  
  func convertToTimeInterval(value: Double, unit: TimeUnit) -> TimeInterval {
      switch unit {
      case .milliseconds:
          return value / 1000
      case .seconds:
          return value
      case .minutes:
          return value * 60
      case .hours:
          return value * 3600
      }
  }
  
  func startTimer(intervalObj: TimerInterval) {
    let interval = convertToTimeInterval(value: intervalObj.value, unit: intervalObj.unit)
    schedule = intervalObj
       timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
          timeElapsed += 1
         Task {
           await Request()
         }
       }
   }
   
  private func stopTimer() {
    schedule = nil
    timer?.invalidate()
    timer = nil
  }
  
  @MainActor
  func Request(page:Int = 1 ) async {
    searchResponseError = nil
    currentPage = page
    if let selectedHost = selectedHost {
      
      searchIndicator = true
      let cacheKey = Self.computeCacheKey(hostId: selectedHost.id, index: selectedIndex)
      var mappedFields: [SquashedFieldsArray]
      let isCacheHit = Self.isCacheValid(fields: fields, fieldsCacheKey: fieldsCacheKey, currentKey: cacheKey)
      let isSameHostAndIndex = fieldsCacheKey == cacheKey

      if isCacheHit {
        mappedFields = fields
      } else {
        mappedFields = await IndexMap.indexMappings(serverDetails: selectedHost, index: selectedIndex)
      }
      
      // Paging keeps the chart from the first page, the counts don't change
      let isFirstPage = page <= 1
      var histogramRequest: SearchHistogramRequest? = nil
      if isFirstPage {
        let dateFieldKey = filterObject.dateField?.squashedString
        histogramRequest = SearchHistogram.request(
          filterObject: filterObject,
          fieldType: mappedFields.first { $0.squashedString == dateFieldKey }?.type,
          version: selectedHost.version)
      }
      
      let response = await SearchRender.call(pageInput: page,
                                             filterObject: filterObject,
                                             host: selectedHost,
                                             index: selectedIndex,
                                             limitObj: LimitObj(size: SettingsDataManager().documentsPerPage),
                                             histogram: histogramRequest)
      
      guard cacheKey == Self.computeCacheKey(hostId: self.selectedHost?.id, index: self.selectedIndex) else {
        searchIndicator = false
        return
      }

      if let duration = response.duration {
        lastLatency = duration
      }

      if let error = response.error {
        searchResponseError = error
        renderedObjects = nil
        histogram = nil
        lastHitCount = nil
      } else {
        searchResponseError = nil
        if isFirstPage {
          histogram = response.histogram
        }
        lastHitCount = (response.hits, response.hitsIsLowerBound)
        
        let searchEvent = RealmSearchEvent.make(host: selectedHost.id,
                                                index: selectedIndex,
                                                filterObject: filterObject)
        SearchHistoryDataManager().addNew(item: searchEvent)
        
        let searchResults = response.results
        resultsFields.fields = response.fields ?? []
        pageCount = response.pages
        
        itemDetail.showingView = false
        
        filteredFields = [SquashedFieldsArray]()
        viewableFields.fields = resultsFields.fields
        let previousOnlyVisible = onlyVisibleFields
        onlyVisibleFields = viewableFields.fields
        //      var fieldsPlaceholder = mappedFields
        //
        for item in mappedFields {
          onlyVisibleFields.forEach { if $0.squashedString == item.squashedString {
            $0.type = item.type
          }
          }
        }
        
        if isCacheHit {
          var unusedTargetFields = [SquashedFieldsArray]()
          Self.syncVisibility(
            sourceFields: fields,
            sourceOnlyVisible: [],
            targetFields: &unusedTargetFields,
            targetOnlyVisible: &onlyVisibleFields
          )
        } else {
          Self.syncVisibility(
            sourceFields: isSameHostAndIndex ? fields : [],
            sourceOnlyVisible: isSameHostAndIndex ? previousOnlyVisible : [],
            targetFields: &mappedFields,
            targetOnlyVisible: &onlyVisibleFields
          )
          fields = mappedFields.sorted(by: {$0.squashedString < $1.squashedString})
          fieldsCacheKey = cacheKey
        }
        
        if !isSameHostAndIndex {
          selectedFieldOrder = []
          tableColumnWidths = macosTableColumn.widths(fromSaved: pendingColumnWidths ?? [:])
          pendingColumnWidths = nil
          if let saved = pendingSelectedFields {
            // A saved search shows the columns it was saved with, even none
            SavedSearch.applySelectedFields(saved,
                                            dateField: filterObject.dateField?.squashedString,
                                            fields: &fields,
                                            onlyVisibleFields: &onlyVisibleFields)
            selectedFieldOrder = saved
            pendingSelectedFields = nil
            updatedFieldsNotification = UUID()
          } else {
            Self.selectAllFieldsIfFew(fields: fields, onlyVisibleFields: onlyVisibleFields)
          }
          if let dateField = filterObject.dateField {
            fields.first { $0.squashedString == dateField.squashedString }?.visible = true
            onlyVisibleFields.first { $0.squashedString == dateField.squashedString }?.visible = true
            dateField.visible = true
            currentActiveDateField = dateField.squashedString
          } else {
            currentActiveDateField = nil
          }
        }
        
        searchResultsUpdated = UUID()
        
        
        renderedObjects = Results.UpdateResultsWithFlatArray(searchResults: searchResults,
                                                             resultsFields: viewableFields,
                                                             datefield: filterObject.dateField,
                                                             rows: response.rows,
                                                             refs: response.refs)
      }
      
      searchIndicator = false
    } else {
      renderedObjects = nil
    }
  }
  
  /// Searches the window dragged across the histogram, keeping the current period to go back to
  func applyChartSelection(from: Date, to: Date) {
    if let current = filterObject.snapshotDateRange() {
      zoomHistory.append(current)
    }
    filterObject.setAbsoluteRange(from: from, to: to)
    // A fixed period has nothing new to refresh
    stopTimer()
    Task {
      await Request()
    }
  }
  
  /// Filters the search for a field's value, or against it, from the Document panel or a table cell,
  /// then closes the panel if it's open and searches again.
  func addFieldFilter(field: String, value: String, negated: Bool) {
    filterObject.addFieldFilter(field: field, value: value, negated: negated)
    selection = .None
    Task {
      await Request()
    }
  }
  
  /// Changes the field filters as a chip asked, then searches again with them.
  func applyChipAction(_ action: FieldFilterChipAction) {
    switch action {
    case .toggleNegated(let id):
      filterObject.toggleFieldFilterNegated(id)
    case .toggleDisabled(let id):
      filterObject.toggleFieldFilterDisabled(id)
    case .remove(let id):
      filterObject.removeFieldFilter(id)
    case .clearAll:
      filterObject.clearFieldFilters()
    }
    Task {
      await Request()
    }
  }
  
  func undoChartZoom() {
    guard let previous = zoomHistory.popLast() else { return }
    filterObject.restore(previous)
    Task {
      await Request()
    }
  }
  
  func handleSubmit() {
    autocomplete.dismiss()
    if !searchText.isEmpty {
      filterObject.query = QueryObject()
      filterObject.query?.values.append(QueryFilterObject(string: searchText))
    } else {
      filterObject.query = nil
    }
      Task {
        await Request ()
      }
    
  }
  
  @State private var currentWidth: CGFloat = 300
  /// The sidebar width when the current resize drag began, nil when not dragging.
  @State private var sidebarResizeStartWidth: CGFloat? = nil
  /// The Document panel's share of the search area, kept between launches so it scales with the window
  @AppStorage("macosDocumentPanelFraction") private var documentPanelFraction: Double = macosSearchMainView.defaultDocumentPanelFraction
  
  @StateObject private var autocomplete = macosQueryAutocompleteModel()
  @State private var queryCursorRequest: TextFieldCursorRequest?

  /// Measures each drag from the width it started at, as the handle moves with the sidebar edge.
  func sidebarResizeChanged(translation: CGFloat) {
    let startWidth = sidebarResizeStartWidth ?? currentWidth
    sidebarResizeStartWidth = startWidth
    if let width = Self.resizedSidebarWidth(start: startWidth, translation: translation) {
      currentWidth = width
    } else {
      showFilterSidebar = false
    }
  }
  @State var showFilterSidebar = true
  
  var topButtonsPadding: CGFloat {
    fullScreen ? 5 : 0
  }
  
  var dropdownTopPadding: CGFloat {
    topButtonsPadding + 33
  }
  
  var datePickerTopPadding: CGFloat {
    topButtonsPadding + 80
  }
  
  var bodyFilteredFields: [SquashedFieldsArray] {
    Self.computeBodyFilteredFields(fields: fields,
                                   activeDateField: filterObject.dateField,
                                   order: selectedFieldOrder)
  }

  var showDateHeader: Bool {
    Self.shouldShowDateHeader(fields: fields, activeDateField: filterObject.dateField)
  }

  /// Hides a field from the right-click menu of its column, as unticking it in the sidebar does.
  /// Its set width goes too, so "Reset column widths" isn't left on for a column that's no longer shown.
  func hideField(_ column: macosTableColumn) {
    if macosTableSearchView.hideField(column, fields: fields, onlyVisibleFields: onlyVisibleFields) {
      tableColumnWidths.removeValue(forKey: column)
      updatedFieldsNotification = UUID()
    }
  }

  /// Shows a clicked row in the Document panel, opening the panel in the same update as the click.
  func openDocument(_ item: OrderedDictionary<String, Any>, ref: DocumentRef?) {
    itemDetail.ref = ref
    itemDetail.item = item
    isDocumentSaved = Self.isSaved(ref, host: selectedHost)
    selection = .SearchDocumentView
  }

  /// Whether the document is in the Saved tab. False without a host or a reference.
  static func isSaved(_ ref: DocumentRef?, host: HostDetails?) -> Bool {
    guard let ref = ref, let host = host, !host.isInvalidated else { return false }
    return SavedDocumentDataManager().find(hostId: host.id, ref: ref) != nil
  }

  /// The search as it stands, for the Saved tab, with its period pinned to fixed dates when `pinPeriod` is set
  func currentSavedSearch(title: String = "", pinPeriod: Bool = false) -> SavedSearch? {
    guard let host = selectedHost, !host.isInvalidated, !selectedIndex.isEmpty else { return nil }
    return SavedSearch.make(hostId: host.id,
                            title: title,
                            searchIndex: selectedIndex,
                            dataView: selectedDataView,
                            filterObject: filterObject,
                            selectedFields: bodyFilteredFields.map(\.squashedString),
                            columnWidths: macosTableColumn.savedWidths(tableColumnWidths),
                            pinPeriod: pinPeriod)
  }

  /// The search as far as saving goes, to compare with the saved search it came from
  var currentSearchState: SavedSearchState {
    SavedSearchState(searchIndex: selectedIndex,
                     dataViewId: selectedDataView?.id,
                     filterObject: filterObject,
                     // Until a saved search's columns are shown, they're still the ones it was saved with
                     selectedFields: pendingSelectedFields ?? bodyFilteredFields.map(\.squashedString),
                     columnWidths: pendingColumnWidths ?? macosTableColumn.savedWidths(tableColumnWidths))
  }

  /// What differs from the saved search this search came from, empty when it didn't come from one
  var savedSearchChanges: [SavedSearchState.Part] {
    savedSearchLink.map { currentSearchState.changes(from: $0.baseline) } ?? []
  }

  /// Opens the Save popover, after checking the saved search it came from is still there under the same name
  func openSavePopover() {
    if let link = savedSearchLink {
      if let saved = SavedSearchDataManager().search(id: link.id) {
        savedSearchLink?.title = saved.displayTitle
        savedSearchLink?.pinnedPeriod = SavedSearchLink.isPinned(saved, baseline: link.baseline)
      } else {
        savedSearchLink = nil
      }
    }
    showingSavePopover = true
  }

  /// Saves the search as a new saved search, which saving again then updates
  func saveSearch(named name: String, pinPeriod: Bool) {
    showingSavePopover = false
    guard let search = currentSavedSearch(title: name, pinPeriod: pinPeriod),
          let saved = try? SavedSearchDataManager().save(search) else { return }
    let baseline = currentSearchState
    savedSearchLink = SavedSearchLink(id: saved.id, title: saved.displayTitle, baseline: baseline,
                                      pinnedPeriod: SavedSearchLink.isPinned(saved, baseline: baseline))
    confirmSave("Saved")
  }

  /// Replaces the saved search this search came from with the search as it stands
  func updateSavedSearch(pinPeriod: Bool) {
    showingSavePopover = false
    guard let link = savedSearchLink, let search = currentSavedSearch(pinPeriod: pinPeriod) else { return }
    do {
      let saved = try SavedSearchDataManager().update(id: link.id, with: search)
      let baseline = currentSearchState
      savedSearchLink?.baseline = baseline
      savedSearchLink?.pinnedPeriod = SavedSearchLink.isPinned(saved, baseline: baseline)
      confirmSave("Updated")
    } catch {
      // Removed from the Saved tab meanwhile, so it can only be saved as a new one
      savedSearchLink = nil
      showingSavePopover = true
    }
  }

  func confirmSave(_ text: String) {
    saveConfirmation = text
    Task {
      try? await Task.sleep(for: .seconds(2))
      if saveConfirmation == text {
        saveConfirmation = nil
      }
    }
  }

  /// The Save button, which opens the save popover
  var saveControl: AnyView? {
    guard selectedHost != nil, !selectedIndex.isEmpty else { return nil }
    let changes = savedSearchChanges
    return AnyView(
      macosSaveSearchButton(confirmation: saveConfirmation,
                            hasChanges: savedSearchLink != nil && !changes.isEmpty,
                            isOpen: showingSavePopover,
                            action: openSavePopover)
        .popover(isPresented: $showingSavePopover, arrowEdge: .bottom) {
          macosSaveSearchPopover(linkedTitle: savedSearchLink?.title,
                                 changes: changes,
                                 suggestedName: currentSavedSearch()?.displayTitle ?? selectedIndex,
                                 period: filterObject.dateField == nil ? nil : filterObject.snapshotDateRange(),
                                 linkedPinned: savedSearchLink?.pinnedPeriod ?? false,
                                 onUpdate: updateSavedSearch(pinPeriod:),
                                 onSaveNew: saveSearch(named:pinPeriod:),
                                 onClose: { showingSavePopover = false })
        }
    )
  }

  /// Saves the open document with this search's date field and time period, or unsaves it
  func toggleSavedDocument() {
    guard let ref = itemDetail.ref, let host = selectedHost, !host.isInvalidated else { return }
    let manager = SavedDocumentDataManager()
    if manager.find(hostId: host.id, ref: ref) != nil {
      manager.delete(hostId: host.id, ref: ref)
    } else {
      let document = SavedDocument.make(hostId: host.id,
                                        ref: ref,
                                        searchIndex: selectedIndex,
                                        dataView: selectedDataView,
                                        dateField: filterObject.dateField,
                                        dateRange: filterObject.snapshotDateRange())
      _ = try? manager.save(document)
    }
    isDocumentSaved = Self.isSaved(ref, host: host)
  }
  
  /// Arrow keys move through the suggestions, Tab takes the highlighted or top one,
  /// Return takes a highlighted one or searches, Escape closes them
  func handleQueryCommand(_ command: CustomNSTextField.Command) -> Bool {
    guard autocomplete.isVisible else { return false }
    switch command {
    case .moveUp:
      autocomplete.moveUp()
      return true
    case .moveDown:
      autocomplete.moveDown()
      return true
    case .tab:
      return acceptSuggestion(at: autocomplete.highlightedIndex ?? 0)
    case .newline:
      guard let index = autocomplete.highlightedIndex else { return false }
      return acceptSuggestion(at: index)
    case .cancel:
      autocomplete.dismiss()
      return true
    }
  }

  @discardableResult
  func acceptSuggestion(at index: Int) -> Bool {
    guard let result = autocomplete.complete(at: index, in: searchText) else { return false }
    searchText = result.text
    queryCursorRequest = TextFieldCursorRequest(location: result.cursor)
    // A chosen field goes straight on to its values
    if result.kind == .field {
      updateAutocomplete(text: result.text, cursor: result.cursor, textChanged: true)
    }
    return true
  }

  func updateAutocomplete(text: String, cursor: Int?, textChanged: Bool) {
    autocomplete.update(text: text,
                        cursor: cursor,
                        textChanged: textChanged,
                        fields: fields,
                        labels: selectedDataView?.labels ?? [:],
                        scope: valueSuggestionScope,
                        loadValues: loadRecentValues(field:))
  }

  /// What value suggestions depend on: the host, index, time field and time period
  var valueSuggestionScope: String {
    let hostId = selectedHost.flatMap { $0.isInvalidated ? nil : $0.id.uuidString } ?? ""
    return [hostId, selectedIndex, filterObject.dateField?.squashedString ?? "", filterObject.dateRangeSignature]
      .joined(separator: "|")
  }

  /// The field's 10 most recent distinct values in the current time period
  func loadRecentValues(field: String) async -> [String] {
    guard let host = selectedHost, !host.isInvalidated, !selectedIndex.isEmpty else { return [] }
    let bounds = SearchHistogram.dateBounds(filterObject: filterObject)
    return await QueryValueSuggestions.fetch(serverDetails: host.generateCopy(),
                                             index: selectedIndex,
                                             field: field,
                                             fieldType: fields.first { $0.squashedString == field }?.type ?? "",
                                             timeField: filterObject.dateField?.squashedString,
                                             from: bounds?.from,
                                             to: bounds?.to)
  }

  /// The histogram shows the document count itself, so the top bar only shows it when there's no histogram
  var showsHistogram: Bool {
    guard let histogram = histogram else { return false }
    return histogram.totalCount > 0 && searchResponseError == nil && selectedHost != nil
  }

  var body: some View {
    ZStack {
      Color("Background")
      
      VStack(spacing:0) {
        macosSearchTopButtonsView(macosSearchRouterPath:$macosSearchRouterPath,
                                    selection: $selection,
                                    showFilterSidebar: $showFilterSidebar,
                                    hostName: selectedHost?.name,
                                    index: selectedIndex,
                                    dataView: selectedDataView,
                                    latency: lastLatency,
                                    hitCountLabel: showsHistogram ? nil : lastHitCount.map {
                                      SearchResult.hitCountLabel($0.count, isLowerBound: $0.isLowerBound)
                                    },
                                    saveControl: saveControl,
                                    currentWidth: $currentWidth)
          .padding(.bottom, 5)
          .padding(.top, topButtonsPadding)
//          .border(.red)
        
        
        HStack(spacing:0) {
          
          HStack (spacing:0) {
            
            
            
            VStack(spacing: 5) {

                SearchInputFieldsView(handleSubmit: handleSubmit,
                                      searchText: $searchText,
                                      selection: $selection,
                                      searchIndicator: $searchIndicator,
                                      cursorRequest: queryCursorRequest,
                                      onQueryEdit: updateAutocomplete(text:cursor:textChanged:),
                                      onQueryCommand: handleQueryCommand(_:),
                                      onQueryEndEditing: {
                                        if !autocomplete.pointerInside {
                                          autocomplete.dismiss()
                                        }
                                      },
                                      schedule: schedule,
                                      stopTimer: stopTimer)
                .id(topBarDateButtonRefresh)
                .onAppear {
                  if let queryString = filterObject.query?.values.first {
                    searchText = queryString.string
                  }
                }
                
                if !filterObject.fieldFilters.isEmpty {
                  macosFieldFilterChipsView(filters: filterObject.fieldFilters,
                                            labels: selectedDataView?.labels ?? [:],
                                            onAction: applyChipAction(_:))
                }
                
                if showsHistogram, let histogram = histogram {
                  macosSearchHistogramView(histogram: histogram,
                                           searchIndicator: searchIndicator,
                                           onSelectRange: applyChartSelection,
                                           backTitle: zoomHistory.last?.title,
                                           onBack: undoChartZoom)
                }
                
                
                macosSearchResultsView(renderedObjects: $renderedObjects,
                                       viewableFields: resultsFields,
                                       fields: bodyFilteredFields,
                                       fieldsVersion: updatedFieldsNotification,
                                       showDateHeader: showDateHeader,
                                       labels: selectedDataView?.labels ?? [:],
                                       columnWidths: $tableColumnWidths,
                                       onHideField: hideField(_:),
                                       onOpenDocument: openDocument(_:ref:),
                                       onFilter: addFieldFilter(field:value:negated:),
                                       activeFilterCount: filterObject.fieldFilters.enabled.count,
                                       selectedHost:$selectedHost,
                                       selectedIndex: $selectedIndex,
                                       itemDetail: itemDetail,
                                       searchResultsUpdated: $searchResultsUpdated,
                                       currentPage: $currentPage,
                                       pageCount: $pageCount,
                                       searchResponseError:$searchResponseError,
                                       searchIndicator:searchIndicator,
                                       Request: { input in
                  Task {
                    await Request(page: input)
                  }
                })
                .disabled(selectedHost == nil)
                .opacity(selectedHost == nil ? 0.5 : 1)
        
            }
            
          macosSidebarResizeHandle(onDrag: sidebarResizeChanged(translation:),
                                   onDragEnd: { sidebarResizeStartWidth = nil })
            .frame(maxWidth: 5)
            
            if fields.count != 0 {
              if showFilterSidebar {
                VStack(alignment: .leading) {
                  
                  macosSearchSideBar(fields: $fields,
                                     onlyVisibleFields: $onlyVisibleFields,
                                     selectedHost: $selectedHost,
                                     selectedIndex: $selectedIndex,
                                     updatedFieldsNotification: $updatedFieldsNotification,
                                     renderedObjects: $renderedObjects,
                                     fieldOrder: $selectedFieldOrder,
                                     dateFieldKey: filterObject.dateField?.squashedString,
                                     labels: selectedDataView?.labels ?? [:],
                                     searchIndicator:searchIndicator){
                    Task {
                      await Request()
                    }
                    
                    
                  }.frame(maxWidth: .infinity)
                  
                }.frame(maxWidth: currentWidth)
                  .id(hostsUpdated.updated)
            
              }
            }
          }
        }
      }.padding(.leading, 3)
      
      
      
      
      if selection != .None {
        
        RoundedRectangle(cornerRadius: 5)
          .fill(Color.black.opacity(0.3))
          .frame(maxWidth: .infinity, alignment: .leading)
          .frame(maxHeight: .infinity)
          .contentShape(RoundedRectangle(cornerRadius: 5))
          .onTapGesture {
            selection = .None
          }
          .padding(.top, dropdownTopPadding)
          .padding(.leading, 2)
          .padding(.trailing, 2)
        
        if selection == .DatePeriod {
          VStack {
            macosDatePickerView(selectedIndex: $selectedIndex,
                                selection: $selection,
                                topBarDateButtonRefresh: $topBarDateButtonRefresh,
                                fields:$fields)
            .frame(maxWidth: 400)
//            .shadow(color: Color("BackgroundAlt"), radius: 5, x: 0, y: 0)
            .padding(.trailing, showFilterSidebar ? 150 : 0)
            
            Spacer()
            
          }
          .frame(maxWidth: .infinity, alignment: .trailing)
          .padding(.top, datePickerTopPadding)
        }
        
        VStack(alignment: .leading, spacing: 0) {
          // Popups
          VStack(alignment: .leading, spacing: 0) {
            if selection == .Hosts {
              macosSidebarHostsDropdownView(items: items,
                                            selectedHost: $selectedHost,
                                            selection: $selection,
                                            fullScreen: $fullScreen)
              
              
            } else if selection == .Indices {
              macosSidebarIndicesDropdownView(selectedIndex: $selectedIndex,
                                              selectedDataView: $selectedDataView,
                                              showingScreen: $showingScreen,
                                              selection: $selection,
                                              filterObject: filterObject,
                                              fullScreen: fullScreen,
                                              selectedHost: selectedHost,
                                              firstSearchAfterSelectingIndex:$firstSearchAfterSelectingIndex,
                                              shouldClearTextfield:$shouldClearTextfield) {
                Task {
                  await Request()
                }
              }
            }
          }
          .frame(width: 340, alignment: .topLeading)
          
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, dropdownTopPadding)
        
       
        if selection == .SearchDocumentView {
          // The panel takes its saved share of the search area, half until it's resized
          GeometryReader { geometry in
            let available = geometry.size.width
            macosDocumentDetailView(itemDetail: itemDetail,
                                    fields: $fields,
                                    onlyVisibleFields: $onlyVisibleFields,
                                    updatedFieldsNotification: $updatedFieldsNotification,
                                    labels: selectedDataView?.labels ?? [:],
                                    width: Self.clampedDocumentPanelWidth(documentPanelFraction * available,
                                                                          available: available),
                                    availableWidth: available,
                                    onResized: { width in
                                      if available > 0 {
                                        documentPanelFraction = width / available
                                      }
                                    },
                                    onResetWidth: {
                                      documentPanelFraction = Self.defaultDocumentPanelFraction
                                    },
                                    fieldFilters: filterObject.fieldFilters,
                                    onFilter: addFieldFilter(field:value:negated:),
                                    onClose: { selection = .None },
                                    isSaved: itemDetail.ref == nil ? nil : isDocumentSaved,
                                    onToggleSaved: toggleSavedDocument)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
          }
        }
        
        if selection == .SearchScreenRefreshFrequency {
          macosSidebarTimerView(timer: $timer,
                                selection: $selection,
                                fullScreen: $fullScreen,
                                showFilterSidebar: $showFilterSidebar,
                                startTimer: startTimer,
                                stopTimer: stopTimer)
        }
        
      }
      
    }
    .overlayPreferenceValue(macosQueryFieldBoundsKey.self) { anchor in
      GeometryReader { proxy in
        if let anchor = anchor, autocomplete.isVisible {
          let field = proxy[anchor]
          macosQueryAutocompleteView(model: autocomplete, onSelect: { acceptSuggestion(at: $0) })
            .frame(width: field.width)
            .padding(.leading, field.minX)
            .padding(.top, field.maxY + 4)
        }
      }
    }
    .onDisappear {
      stopTimer()
    }
    .onAppear {
      Task {
        items = serverObjects.items
        currentActiveDateField = filterObject.dateField?.squashedString
        await Request()
      }
      
    }
    .onChange(of: filterObject.dateField?.squashedString) { _ in
      if Self.switchDateField(
        newDateField: filterObject.dateField,
        currentActiveDateField: &currentActiveDateField,
        fields: &fields,
        onlyVisibleFields: &onlyVisibleFields,
        renderedObjects: &renderedObjects
      ) {
        updatedFieldsNotification = UUID()
      }
    }
    .onChange(of: selection) { newValue in
      if newValue != .None {
        autocomplete.dismiss()
      }
      // Choosing a new time period turns off auto refresh
      if newValue == .DatePeriod {
        dateRangeWhenPickerOpened = filterObject.dateRangeSignature
      } else if let openedWith = dateRangeWhenPickerOpened {
        dateRangeWhenPickerOpened = nil
        if openedWith != filterObject.dateRangeSignature {
          stopTimer()
          zoomHistory = []
        }
      }
    }
    .onChange(of: hostsUpdated.updated) { _ in
      Task {
        serverObjects.refresh()
        items = serverObjects.items
        if items.count == 1 {
          selectedHost = items.first
        }
      }
    }
    .onChange(of: filterObject.query?.values.first?.string) { newValue in
      if newValue != searchText {
        lastValue = newValue ?? ""
        searchText = lastValue
      }
    }
    // The index list sets the date field and data view itself before changing the index:
    // reset for an index, or the view's time field for a data view. Doing it here instead
    // would rely on reading the data view while the change is still being applied.
    .onChange(of: selectedIndex) { _ in
      searchResponseError = nil
      lastLatency = nil
      lastHitCount = nil
      histogram = nil
      zoomHistory = []
      currentPage = 0
    }
    .onChange(of: selectedHost?.id) { _ in
      selectedDataView = nil
      searchResponseError = nil
      lastLatency = nil
      lastHitCount = nil
      histogram = nil
      zoomHistory = []
      selectedIndex = ""
      currentPage = 0
      filterObject.resetIndexSpecificFilters()
      // Field filters belong to the old host's fields. Recent searches are restored from the home
      // screen, where this view isn't shown, so this doesn't clear the filters they bring back
      filterObject.clearFieldFilters()
    }
    .onChange(of: shouldClearTextfield) { newValue in
      if newValue {
        filterObject.query = nil
        lastValue = ""
        searchText = ""
        shouldClearTextfield = false
      }
    }
    .environmentObject(filterObject)
  }
}

extension macosSearchMainView {
  public static let minSidebarWidth: CGFloat = 200
  public static let maxSidebarWidth: CGFloat = 600

  /// The sidebar width after dragging its left edge by `translation`, capped at the maximum.
  /// Returns nil when it's dragged narrower than the minimum, which hides the sidebar.
  public static func resizedSidebarWidth(start: CGFloat, translation: CGFloat) -> CGFloat? {
    let width = start - translation
    if width < minSidebarWidth {
      return nil
    }
    return min(width, maxSidebarWidth)
  }

  public static let defaultDocumentPanelFraction: Double = 0.5
  public static let minDocumentPanelWidth: CGFloat = 320
  /// The results stay at least this wide beside the Document panel
  public static let minResultsWidthBesideDocumentPanel: CGFloat = 200

  /// Keeps the Document panel between its minimum and the width that leaves room for the results.
  /// The minimum wins when the search area is too narrow for both.
  public static func clampedDocumentPanelWidth(_ width: CGFloat, available: CGFloat) -> CGFloat {
    max(minDocumentPanelWidth, min(width, available - minResultsWidthBesideDocumentPanel))
  }

  /// The Document panel width after dragging its left edge by `translation`: left widens it, right narrows it.
  /// It stops at the minimum rather than closing.
  public static func resizedDocumentPanelWidth(start: CGFloat, translation: CGFloat, available: CGFloat) -> CGFloat {
    clampedDocumentPanelWidth(start - translation, available: available)
  }

  public static func computeCacheKey(hostId: UUID?, index: String) -> String {
    "\(hostId?.uuidString ?? "")|\(index)"
  }

  public static func isCacheValid(fields: [SquashedFieldsArray], fieldsCacheKey: String, currentKey: String) -> Bool {
    !fields.isEmpty && fieldsCacheKey == currentKey
  }

  public static func syncVisibility(
    sourceFields: [SquashedFieldsArray],
    sourceOnlyVisible: [SquashedFieldsArray],
    targetFields: inout [SquashedFieldsArray],
    targetOnlyVisible: inout [SquashedFieldsArray]
  ) {
    let visibleKeys = Set((sourceFields + sourceOnlyVisible).filter { $0.visible }.map { $0.squashedString })

    for field in targetFields {
      if visibleKeys.contains(field.squashedString) {
        field.visible = true
      }
    }

    for field in targetOnlyVisible {
      if visibleKeys.contains(field.squashedString) {
        field.visible = true
      }
    }

    var existingTargetKeys = Set(targetFields.map { $0.squashedString })
    for field in sourceFields where field.visible && !existingTargetKeys.contains(field.squashedString) {
      targetFields.append(field)
      existingTargetKeys.insert(field.squashedString)
    }
  }

  /// Indexes with fewer mapped fields than this get every field selected on their first search.
  public static let autoSelectAllFieldsLimit = 10

  /// Selects every field when the index has only a few, so the grid shows each one as a column
  /// instead of a single Document column. Returns whether the fields were selected.
  @discardableResult
  public static func selectAllFieldsIfFew(
    fields: [SquashedFieldsArray],
    onlyVisibleFields: [SquashedFieldsArray],
    limit: Int = autoSelectAllFieldsLimit
  ) -> Bool {
    guard !fields.isEmpty, fields.count < limit else { return false }
    let keys = Set(fields.map { $0.squashedString })
    fields.forEach { $0.visible = true }
    onlyVisibleFields.filter { keys.contains($0.squashedString) }.forEach { $0.visible = true }
    return true
  }

  /// Computes the list of active body filters by excluding the active date field from visible fields.
  /// The active date field is presented separately in the card header, not in the body textArray.
  /// When no body fields are explicitly selected by the user (even if the date field is active by default),
  /// the body displays all document fields unfiltered. Once one or more body fields are selected,
  /// the body is filtered strictly to those selected fields, in the column `order` the user dragged them into.
  public static func computeBodyFilteredFields(
    fields: [SquashedFieldsArray],
    activeDateField: SquashedFieldsArray?,
    order: [String] = []
  ) -> [SquashedFieldsArray] {
    macosSearchFieldSheetView.orderSelectedFields(
      fields.filter { $0.visible && $0.squashedString != activeDateField?.squashedString },
      order: order)
  }

  public static func shouldShowDateHeader(
    fields: [SquashedFieldsArray],
    activeDateField: SquashedFieldsArray?
  ) -> Bool {
    guard let dateField = activeDateField else { return false }
    return fields.contains { $0.squashedString == dateField.squashedString && $0.visible }
  }

  @discardableResult
  public static func switchDateField(
    newDateField: SquashedFieldsArray?,
    currentActiveDateField: inout String?,
    fields: inout [SquashedFieldsArray],
    onlyVisibleFields: inout [SquashedFieldsArray],
    renderedObjects: inout RenderObject?
  ) -> Bool {
    let newSquashed = newDateField?.squashedString
    guard newSquashed != currentActiveDateField else { return false }
    if let oldDateField = currentActiveDateField {
      fields.first { $0.squashedString == oldDateField }?.visible = false
      onlyVisibleFields.first { $0.squashedString == oldDateField }?.visible = false
    }
    if let newSquashed = newSquashed {
      fields.first { $0.squashedString == newSquashed }?.visible = true
      onlyVisibleFields.first { $0.squashedString == newSquashed }?.visible = true
      newDateField?.visible = true
    }
    renderedObjects?.dateField = newDateField
    currentActiveDateField = newSquashed
    return true
  }
}

/// The grab area on the sidebar's left edge: shows the resize cursor and reports drags.
/// It needs a content shape, as a clear fill alone gets hover events but not drags.
struct macosSidebarResizeHandle: View {
  let onDrag: (_ translation: CGFloat) -> Void
  let onDragEnd: () -> Void
  /// Told when the pointer starts or stops hovering or dragging, so a grip can highlight
  var onActiveChanged: ((Bool) -> Void)? = nil
  var onDoubleClick: (() -> Void)? = nil

  @State private var isHovered = false
  @State private var isDragging = false
  @State private var showsCursor = false

  /// Keeps the resize cursor until both the hover and the drag have ended,
  /// as the pointer can leave this narrow area part way through a drag.
  func updateCursor() {
    let wanted = isHovered || isDragging
    if wanted && !showsCursor {
      NSCursor.resizeLeftRight.push()
    } else if !wanted && showsCursor {
      NSCursor.pop()
    }
    if wanted != showsCursor {
      onActiveChanged?(wanted)
    }
    showsCursor = wanted
  }

  var body: some View {
    Color.clear
      .contentShape(Rectangle())
      .onHover { hovering in
        isHovered = hovering
        updateCursor()
      }
      // Global coordinates, as the handle itself moves with the sidebar edge while it's dragged
      .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .global)
        .onChanged { value in
          isDragging = true
          updateCursor()
          onDrag(value.translation.width)
        }
        .onEnded { _ in
          isDragging = false
          updateCursor()
          onDragEnd()
        })
      .onTapGesture(count: 2) {
        onDoubleClick?()
      }
      .onDisappear {
        isHovered = false
        isDragging = false
        updateCursor()
      }
  }
}

#endif
