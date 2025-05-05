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

class DocumentDetail: ObservableObject {
  @Published var item: OrderedDictionary<String, Any>? = nil {
    didSet {
      if item != nil {
        showingView = true
      }
    }
  }
  
  @Published var headers : [SquashedFieldsArray]?
  
  @Published var showingView : Bool = false
  
  public func asJson () -> String {
    guard let item = item else { return "" }
    var myDic = Dictionary<String, Any>()
    for el in item {
      
      myDic.updateValue(el.value, forKey: el.key)
    }
    
    let jsonString = JSON(myDic).rawString(options:[.sortedKeys, .withoutEscapingSlashes, .prettyPrinted]) ?? ""
    return jsonString
    
  }
}

#if os(iOS)
struct SearchMainView: View {
	
	@StateObject var selectedHost: HostDetailsWrap = HostDetailsWrap()
	@StateObject var limitObj : LimitObj = LimitObj()
    @StateObject var filterObject : FilterObject = FilterObject()
    @ObservedObject var searchHistoryManager : SearchHistoryDataManager
    @ObservedObject var filterHistoryDataManager : FilterHistoryDataManager
  
	// -----------------------------------------------
	// FIELDS
	//
	
	// all the fields from results, used for the grid
	@StateObject var resultsFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
	
	// all fields from the documents, by default
	@ObservedObject var viewableFields: RenderedFields = RenderedFields(fields: [SquashedFieldsArray]())
	
	// filtered fields
	@State var filteredFields = [SquashedFieldsArray]()
	
	// fileds from _mapping
	@State var fields = [SquashedFieldsArray]()
	
	// -----------------------------------------------
	
	// detailed item view
	@ObservedObject var itemDetail : DocumentDetail = DocumentDetail()
	
	// Defines the selected index
	@State var selectedIndex: String = ""
	
	// Triggers the search request
	@State var makeSearchRequest: Bool = false
	@State var presentedSheet: SearchSheet?
	
	@State var updatedFieldsNotification : UUID = UUID()
	@State var postRequestUpdate : UUID = UUID()
	
	@State var searchResults : [[String: Any]]? = nil {
		didSet {
			if searchResults != nil && searchResults?.count ?? 0 > 0 {
				validSearchResults = true
			} else {
				validSearchResults = false
			}
		}
	}
	@State var validSearchResults : Bool = false
	
	@State var showingDetailedView : Bool = false
	
	@State var showingAllButtons = true
	
  @State var loadingSpinner : Bool = false
  @State var loadingBody : Bool = false
	@State var renderedObjects : RenderObject?
	
	@State var hitCount: Int = 0
	@State var page : Int = 1
	@State var pageCount : Int = 0
	@State var showingGrid : Bool = false
	
	@State var lastShownAllIndexWarning = Date.distantPast
	
	@EnvironmentObject var orientation : Orientation
	
	@State var hideNavigation = true
	
	let baseAnimation = Animation.linear(duration: 0.5)
	
	@State var hidePagination : Bool = true
	@State var hideBottomBar : Bool = true
	@State var hasInitiallyLoaded = false
	@State var showDateInputView : DateQuery? = nil
	
	@State var indexArray : [String] = [String]()
  
  @AppStorage("lastSeenVersionNotes") private var lastSeenVersionNotes: String = ""
  
  @State private var timeElapsed = 0
  @State private var timer: Timer?
  @State private var schedule: TimerInterval?
  
  @State var searchResponseError : ResponseError?
  
  @State var initialRecentScreen = false
  @Binding var hasShownInitialScreen : Bool
  @State var loadingFields : String = ""
  
	func ClearScreen() {
		fields =  []
		filteredFields = []
		validSearchResults = false
		searchResults = nil
		hitCount = 0
	}
	
	@State var errorMessage = [ResponseError]()
  
  func getMappedFields() async {
    if let item = selectedHost.item,
       fields.count == 0 {
      loadingFields = "Requesting Mapping"
      fields = await IndexMap.indexMappings(serverDetails: item, index: selectedIndex)
      loadingFields=""
    }
  }

  @MainActor
  func historyCall (_ selectedHost: HostDetails, _ selectedIndex: String, _ localFilterObject: FilterObject) -> () {
    self.selectedHost.item = selectedHost
    self.selectedIndex = selectedIndex
    self.filterObject.dateField = localFilterObject.dateField
    self.filterObject.absoluteRange = localFilterObject.absoluteRange
    self.filterObject.relativeRange = localFilterObject.relativeRange
    self.filterObject.sort = localFilterObject.sort
    self.filterObject.query = localFilterObject.query
    Task {
        await getMappedFields()
        await FetchResults()
    }
  }
  
	
  func FetchResults(pageInput: Int = 0) async {
    
    loadingSpinner = true
    
    SearchMainViewLogic2.SaveFilter(filterObject: filterObject,
                                   manager: filterHistoryDataManager)
    
    if let hostId = selectedHost.item?.id {
      var searchEvent = RealmSearchEvent()
      searchEvent.date = Date.now
      searchEvent.host = hostId
      searchEvent.index = selectedIndex
      searchEvent.query = filterObject.query?.eject()
      if let dateField = filterObject.dateField {
        searchEvent.dateField = RealmSquashedFieldsArray(squasedField: dateField)
      }
      searchEvent.relativeRange = filterObject.relativeRange?.ejectRealmObject()
      searchEvent.absoluteRange = filterObject.absoluteRange?.ejectRealmObject()
      if let sortObject = filterObject.sort?.ejectRealmObjet() {
        searchEvent.sortObject = sortObject
      }
      SearchHistoryDataManager().addNew(item: searchEvent)
    }

    var errorArray = [ResponseError]()
    
    if selectedIndex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      errorArray.append(ResponseError(title:"Default Index",
                                      message:"Search defaulting to _all index as no Index has been selected!",
                                      type:.information))
    }
    
    if let host = selectedHost.item {
      
      if (filterObject.absoluteRange != nil ||
          filterObject.relativeRange != nil) &&
          filterObject.dateField == nil {
        
        let datefieldError = ResponseError(title: "Missing Datefield",
                                           message: "A Date Range has been set without selecting a Date field. Open Hosts to select a field of type Date.",
                                           type:.warn)
        
        errorArray.append(datefieldError)
        
      }
      
      let response = await SearchRender.call(pageInput: pageInput,
                                             filterObject: filterObject,
                                             host: host,
                                             index: selectedIndex,
                                             limitObj: limitObj)
      
      
      if let error = response.error {
        
        errorArray.append(error)
        
        ClearScreen()
      } else {
        searchResults = response.results
        hitCount = response.hits
        resultsFields.fields = response.fields ?? []
        pageCount = response.pages
        
        if fields.count == 0 {
          let fieldsResponse = await IndexMap.indexMappings(serverDetails: host,
                                                            index: selectedIndex)
          
          
        }
        //				 = response.mapping ?? []
      }
      
      // if the error list contains critical errors
      // focus on them to show
      if errorArray.contains(where: {$0.type == .critical}) {
        withAnimation(Animation.linear(duration: 0.3)){
          errorMessage.append(contentsOf: errorArray.filter({$0.type == .critical}))
        }
      } else {
        withAnimation(Animation.linear(duration: 0.3)){
          errorMessage.append(contentsOf: errorArray)
        }
      }
      
    }
    
    if pageInput == 0 {
      page=1
    }
    
    loadingSpinner=false
    loadingBody=false
    postRequestUpdate=UUID()
    
  }
  
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

//           validSearchResults = false
           
           Task { @MainActor in
             await FetchResults()
           }
           
           // Reset the request to false after the request completes
           // or times out
           makeSearchRequest=false
         }
       }
   }
   
  private func stopTimer() {
    schedule = nil
    timer?.invalidate()
    timer = nil
  }
  
  private func changingIndex() {
    filteredFields = [SquashedFieldsArray]()
    validSearchResults = false
    searchResults = nil
    hitCount = 0
    filterObject.dateField = nil
    filterObject.absoluteRange = nil
    filterObject.relativeRange = nil
    
    if selectedIndex != "" {
      Task {
        await getMappedFields()
      }
    } else {
      fields = [SquashedFieldsArray]()
    }
  }
  
  private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
  
  @State private var settingsDetent = PresentationDetent.medium
  
  var body: some View {
    
    VStack(alignment: .leading, spacing: 0) {
      
      if showingAllButtons {
        SearchQueryBuilder(presentedSheet:$presentedSheet,
                           validSearchResults: $validSearchResults,
                           showingGrid: $showingGrid,
                           makeSearchRequest: $makeSearchRequest,
                           loading: $loadingSpinner,
                           selectedIndex: selectedIndex,
                           stopTimer: stopTimer,
                           schedule:schedule)
        
        .padding(.horizontal, 8)
        .padding(.bottom, 5)
        .padding(.top, 5)
      }
      
      if showingAllButtons {
        SearchMainStatusView(errorMessage : $errorMessage,
                             selectedIndex : selectedIndex)
      }
      
      SearchDisplayMainView(validSearchResults: validSearchResults,
                            showingGrid: showingGrid,
                            searchResults: $searchResults,
                            viewableFields: viewableFields,
                            updatedFieldsNotification: $updatedFieldsNotification,
                            renderedObjects: $renderedObjects,
                            filteredFields: $filteredFields,
                            itemDetail: itemDetail,
                            showingAllButtons: $showingAllButtons,
                            loading: $loadingBody,
                            hitCount: hitCount,
                            page: $page,
                            pageCount: pageCount,
                            hideNavigation: $hideNavigation,
                            hidePagination: $hidePagination,
                            hideBottomBar: $hideBottomBar,
                            postRequestUpdate: $postRequestUpdate)
      
      
      
    }
    .toolbar(hideNavigation ? .hidden : .visible, for: .tabBar)
    .toolbarBackground(Color("TabBarColor"), for: .tabBar)
    .onAppear {
      
      if selectedHost.item?.isInvalidated ?? false {
        selectedHost.item = nil
        selectedIndex = ""
        ClearScreen()
      }
      
      if !hasInitiallyLoaded {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          withAnimation(Animation.linear(duration: 1)) {
            hideNavigation = false
          }
        }
        hasInitiallyLoaded=true
      }
      
    }
    .onChange(of: selectedHost.item) { newValue in
      
      if newValue == nil {
        // hide the bottomBar and expand button
        // so that it can animate in when the view appears
        hidePagination = true
        hideBottomBar = true
      }
      
      ClearScreen()
      
    }
    .onDisappear {
      stopTimer()
    }
    .onChange(of: resultsFields.fields) { _ in
      // Show everything
      viewableFields.fields=Results.SortedFieldsWithDate(input: resultsFields.fields)
      updatedFieldsNotification=UUID()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Background"))
    .environmentObject(selectedHost)
    .environmentObject(filterObject)
    .onAppear {
      if lastSeenVersionNotes == "2.0",
         searchHistoryManager.items.count > 0,
         !hasShownInitialScreen {
        hasShownInitialScreen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          initialRecentScreen = true
        }
      }
    }
    .sheet(isPresented:$initialRecentScreen) {
      if idiom == .pad {
        iosSearchRecentView(searchHistoryManager: searchHistoryManager,
                            request: historyCall)
      }
      else {
        iosSearchRecentView(searchHistoryManager: searchHistoryManager,
                            request: historyCall)
        .presentationDetents(
                           [.medium, .large],
                           selection: $settingsDetent
                        )
      }
    }
    .sheet(item: $presentedSheet,
           content: { sheet in
      // Prevent weird loop bug
      Group {
        switch sheet {
          
        case .query:
          QueryMainSheet(selectedIndex: $selectedIndex,
                         makeSearchRequest: $makeSearchRequest,
                         showDateInputView: $showDateInputView,
                         fields: fields)
        case .fields:
          SearchFieldSheetView(filteredFields: $filteredFields,
                               updatedFieldsNotification: $updatedFieldsNotification,
                               selectedIndex: selectedIndex,
                               fields: $fields)
          
        case .main:
          SearchMainSheet(selectedIndex: $selectedIndex,
                          makeSearchRequest: $makeSearchRequest,
                          fields:$fields,
                          loadingFields:$loadingFields,
                          indexArray:$indexArray,
                          changingIndex:changingIndex)
          
        case .timer:
          iosSearchTimerView(timer: $timer,
                             startTimer: startTimer,
                             stopTimer: stopTimer)
          
        case .recent:
          iosSearchRecentView(searchHistoryManager: searchHistoryManager,
                              request: historyCall)
          
        }
      }
      .environmentObject(selectedHost)
      .environmentObject(limitObj)
      .environmentObject(filterObject)
    })
    .onChange(of: presentedSheet) { newValue in
      if newValue == .query {
        //show everything if you pop into a query
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          showingAllButtons = true
          
          if hitCount > 0 {
            hidePagination = false
            hideBottomBar = false
          }
        }
      }
    }
    .onChange(of: itemDetail.showingView) { newValue in
      // Because of a ordered dictionary
      // can't trigger a change
      if newValue {
        itemDetail.showingView = false
        showingDetailedView = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          // hide the bottomBar and expand button
          // so that it can animate in when the view appears
          hidePagination = true
          hideBottomBar = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          withAnimation(Animation.linear(duration: 1)) {
            hideNavigation = true
          }
          
        }
      }
    }
    .navigationDestination(isPresented:$showingDetailedView, destination: {
      SearchDetailView(itemDetail: itemDetail,
                       presentedSheet: $presentedSheet,
                       fields: $fields,
                       showDateInputView: $showDateInputView)
      .environmentObject(filterObject)
      .onDisappear {
        // animate the views if we are not showing the modal
        if presentedSheet == nil {
          
          withAnimation( Animation.linear(duration: 0.5)) {
            hideNavigation = false
          }
          
        } else {
          hideNavigation = false
        }
      }
    })
//    .onChange(of: selectedIndex) { newValue in
////      fields =  [SquashedFieldsArray]()
//     
//    }
    .onChange(of: loadingSpinner) { newValue in
      if !newValue { // finished loading
        if hitCount == 0 {
          withAnimation( Animation.linear(duration: 0.5)) {
            hideBottomBar = true
            hidePagination = true
          }
        }
      }
    }
    .onChange(of: page){ newValue in

      validSearchResults=false
      loadingSpinner=true
      loadingBody=true
      
      withAnimation(Animation.linear(duration: 0.3)){
        errorMessage.removeAll()
      }
      // wait for the animation to finish
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        
        //				if selectedIndex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        //
        //					let delta = lastShownAllIndexWarning.distance(to: Date.now)
        //
        //					if delta > 60 {
        //						lastShownAllIndexWarning = Date.now
        //						errorMessage.append(ResponseError(title:"Default Index",
        //																							message:"Search defaulting to _all index as no Index has been selected!"))
        //					}
        //				}
        
        Task { @MainActor in
          await FetchResults(pageInput:newValue)
        }
      }
    }
    .onChange(of: makeSearchRequest){ newValue in
      // Using a state to notify this view when the search button has been pressed
      // TODO move this?
      if newValue {
        
        withAnimation(Animation.linear(duration: 0.3)){
          errorMessage.removeAll()
        }
        
        // wait for the animation to finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          
          
          loadingBody = true
          
          validSearchResults = false
          
          Task { @MainActor in
            await FetchResults()
          }
          
          // Reset the request to false after the request completes
          // or times out
          makeSearchRequest=false
        }
      }
    }
  }
}
#endif
