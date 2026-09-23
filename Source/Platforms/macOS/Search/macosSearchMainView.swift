// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

#if os(macOS)

struct macosSearchMainView: View {
  @Binding var macosSearchRouterPath : macosSearchRouterPath
  @ObservedObject var serverObjects: HostsDataManager
  @State private var searchText = ""
  @Binding var selectedHost: HostDetails?
  @Binding var selectedIndex: String
  
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
  
  @State var updatedFieldsNotification : UUID = UUID()

  // detailed item view
  @StateObject var itemDetail : DocumentDetail = DocumentDetail()
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
  
  @State var searchResponseError : ResponseError?
  
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
    var interval = convertToTimeInterval(value: intervalObj.value, unit: intervalObj.unit)
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
      
      let response = await SearchRender.call(pageInput: page,
                                             filterObject: filterObject,
                                             host: selectedHost,
                                             index: selectedIndex,
                                             limitObj: LimitObj())
      
      guard cacheKey == Self.computeCacheKey(hostId: self.selectedHost?.id, index: self.selectedIndex) else {
        searchIndicator = false
        return
      }
      
      if let error = response.error {
        searchResponseError = error
        renderedObjects = nil
      } else {
        searchResponseError = nil
        
        var searchEvent = RealmSearchEvent()
        searchEvent.date = Date.now
        searchEvent.host = selectedHost.id
        searchEvent.index = selectedIndex
        searchEvent.filter = filterObject.ejectRealmObject()
        
        SearchHistoryDataManager().addNew(item: searchEvent)
        
        let searchResults = response.results
        let hitCount = response.hits
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
                                                             datefield: filterObject.dateField)
      }
      
      searchIndicator = false
    } else {
      renderedObjects = nil
    }
  }
  
  func handleSubmit() {
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
  
  @State var textFieldWidth : CGFloat = 0
  @State var showFilterSidebar = true
  @Binding var showingTextFieldSuggestions : Bool
  
  var topButtonsPadding: CGFloat {
    fullScreen ? 5 : 0
  }
  
  var dropdownTopPadding: CGFloat {
    topButtonsPadding + 33
  }
  
  var datePickerTopPadding: CGFloat {
    topButtonsPadding + 80
  }
  
  var suggestionsTopPadding: CGFloat {
    topButtonsPadding + 85
  }

  var bodyFilteredFields: [SquashedFieldsArray] {
    Self.computeBodyFilteredFields(fields: fields, activeDateField: filterObject.dateField)
  }

  var showDateHeader: Bool {
    Self.shouldShowDateHeader(fields: fields, activeDateField: filterObject.dateField)
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
                                      textFieldWidth: $textFieldWidth,
                                      schedule: schedule,
                                      stopTimer: stopTimer)
                .id(topBarDateButtonRefresh)
                .onAppear {
                  if let queryString = filterObject.query?.values.first {
                    searchText = queryString.string
                  }
                }
                
                
                macosSearchResultsView(renderedObjects: $renderedObjects,
                                       viewableFields: resultsFields,
                                       fields: bodyFilteredFields,
                                       showDateHeader: showDateHeader,
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
                .id(updatedFieldsNotification)
        
            }
            
          Rectangle().fill(.clear)
            .frame(maxWidth: 5)
            .onHover { inside in
              if inside {
                NSCursor.resizeLeftRight.push()
              } else {
                NSCursor.pop()
              }
            }
            .gesture(DragGesture()
              .onChanged { value in
                let position = currentWidth + (value.translation.width * -1)
                if position > 600 {
                  currentWidth = 600
                } else if position < 200 {
                  showFilterSidebar = false
                } else {
                  currentWidth = position
                }
              }
              .onEnded { value in
                let position = currentWidth + (value.translation.width * -1)
                if position > 600 {
                  currentWidth = 600
                } else if position < 200 {
                  showFilterSidebar = false
                } else {
                  currentWidth = position
                }
              }
            )
            
            if fields.count != 0 {
              if showFilterSidebar {
                VStack(alignment: .leading) {
                  
                  macosSearchSideBar(fields: $fields,
                                     onlyVisibleFields: $onlyVisibleFields,
                                     selectedHost: $selectedHost,
                                     selectedIndex: $selectedIndex,
                                     updatedFieldsNotification: $updatedFieldsNotification,
                                     renderedObjects: $renderedObjects,
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
          VStack {
            macosDocumentDetailView(itemDetail: itemDetail,
                                    fields: $fields,
                                    onlyVisibleFields: $onlyVisibleFields,
                                    updatedFieldsNotification: $updatedFieldsNotification)
        
          }
          .frame(maxWidth: .infinity, alignment:.trailing)
          
          
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
      
      if showingTextFieldSuggestions {
        
        VStack {
          HStack {
            macosSidebarAutoSuggest(selection: $selection,
                                    searchText: $searchText,
                                    fields: $fields,
                                    lastValue: $lastValue)
              .frame(maxWidth: textFieldWidth)
            Spacer()
          }
          .padding(.top, suggestionsTopPadding)
          .padding(.leading, 5)
          
        }.frame(maxWidth: .infinity, alignment:.leading)
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
    .onChange(of: hostsUpdated.updated) { _ in
      Task {
        serverObjects.refresh()
        items = serverObjects.items
        if items.count == 1 {
          selectedHost = items.first
        }
      }
    }
    .onChange(of: itemDetail.showingView) { newValue in
      if newValue {
        selection = .SearchDocumentView
      }
    }
    .onChange(of: filterObject.query?.values.first?.string) { newValue in
      if newValue != searchText {
        lastValue = newValue ?? ""
        searchText = lastValue
      }
    }
    .onChange(of: selectedIndex) { newValue in
      searchResponseError = nil
      currentPage = 0
      filterObject.resetIndexSpecificFilters()
    }
    .onChange(of: selectedHost?.id) { _ in
      searchResponseError = nil
      selectedIndex = ""
      currentPage = 0
      filterObject.resetIndexSpecificFilters()
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

  /// Computes the list of active body filters by excluding the active date field from visible fields.
  /// The active date field is presented separately in the card header, not in the body textArray.
  /// When no body fields are explicitly selected by the user (even if the date field is active by default),
  /// the body displays all document fields unfiltered. Once one or more body fields are selected,
  /// the body is filtered strictly to those selected fields.
  public static func computeBodyFilteredFields(
    fields: [SquashedFieldsArray],
    activeDateField: SquashedFieldsArray?
  ) -> [SquashedFieldsArray] {
    fields.filter { $0.visible && $0.squashedString != activeDateField?.squashedString }
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

#endif
