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
  @State var textRefresh = UUID()
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
         print(timeElapsed)
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
    if let selectedHost = selectedHost {
      
//      renderedObjects = nil
      
      searchIndicator = true
      let mappedFields = await IndexMap.indexMappings(serverDetails: selectedHost, index: selectedIndex)
      
      let datefields = mappedFields.filter { $0.type == "date" }
      
      
      // TODO, should this go in the call above?
//      if !firstSearchAfterSelectingIndex {
        var searchEvent = RealmSearchEvent()
        searchEvent.date = Date.now
        searchEvent.host = selectedHost.id
        searchEvent.index = selectedIndex
        searchEvent.filter = filterObject.ejectRealmObject()
        
        SearchHistoryDataManager().addNew(item: searchEvent)
//      }
      
      
      let response = await SearchRender.call(pageInput: page,
                                             filterObject: filterObject,
                                             host: selectedHost,
                                             index: selectedIndex,
                                             limitObj: LimitObj())
      
      if let error = response.error {
        searchResponseError = error
      } else {
        
        let searchResults = response.results
        let hitCount = response.hits
        resultsFields.fields = response.fields ?? []
        currentPage = page
        pageCount = response.pages
        
        itemDetail.showingView = false
        
        filteredFields = [SquashedFieldsArray]()
        viewableFields.fields = resultsFields.fields
        onlyVisibleFields = viewableFields.fields
        //      var fieldsPlaceholder = mappedFields
        //
        for item in mappedFields {
          onlyVisibleFields.forEach { if $0.squashedString == item.squashedString {
            $0.type = item.type
          }
          }
        }
        
        if page == 1 {
          fields = mappedFields.sorted(by: {$0.squashedString < $1.squashedString})
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
    textRefresh=UUID()
    
  }
  
  @State private var currentWidth: CGFloat = 300
  
  @State var textFieldWidth : CGFloat = 0
  @State var showFilterSidebar = true
  @Binding var showingTextFieldSuggestions : Bool
  
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
          .padding(.top, fullScreen ? 5: 0)
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
                                       fields: fields.filter {$0.visible},
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
        
        Rectangle().fill(Color.black).opacity(0.4)
          .frame(maxWidth: .infinity, alignment: .leading)
          .frame(maxHeight: .infinity)
          .contentShape(Rectangle())
          .onTapGesture {
            selection = .None
          }
        
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
          .padding(.top,80)
          .padding(.top, fullScreen ? 5 : 0)
        }
        
        VStack {
          // Popups
          VStack {
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
          }.frame(maxWidth: currentWidth, alignment:.leading)
          
          
         
        
          
          
        }.frame(maxWidth: .infinity, alignment:.leading)
        
       
        if selection == .SearchDocumentView {
          VStack {
            macosDocumentDetailView(itemDetail: itemDetail)
        
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
          .padding(.top, 85)
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
        await Request()
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
    .onChange(of: filterObject.id) { newValue in
      
      if filterObject.query?.values.first?.string != searchText {
        lastValue = filterObject.query?.values.first?.string ?? ""
        searchText = lastValue
        
      }
    }
    .onChange(of: selectedIndex) { newValue in
      filterObject.dateField = nil
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

#endif
