// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI


enum macosSearchWelcomeScreenMainView: Hashable {
  case All
  case NewSearch
  case Recent
}

enum macosSearchPopoverSelection: Hashable {
  case None
  case DatePicker
}

// Main view
// New Search
// Recent Searches
struct macosSearchHomeViewCollection: View {
  
  @State var showing : macosSearchWelcomeScreenMainView = .All
  @State var indexArray = [String]()
  @Binding var selection: macosSearchViewEnum
  
  @Binding var fullScreen : Bool
  
  @State var localSelectedHost: HostDetails?
  @State var localSelectedIndex : String = ""
  @State var loadingIndices : Bool = false
  @State var loadingFieldsMapping : Bool = false
  
  @State var indexError: ResponseError? = nil
  
  @StateObject var localFilterObject : FilterObject = FilterObject()
  @ObservedObject var serverObjects : HostsDataManager
  @State var fields : [SquashedFieldsArray] = [SquashedFieldsArray]()
  
  @State var relativeCustomdatePeriod : SearchDateTimePeriods? = .Minutes
  
  @Binding var sidebar : sideBar
  
  var request : (_ selectedHost: HostDetails, _ selectedIndex: String, _ filterObject: FilterObject) -> ()
  
  func unselectedHost() {
    localSelectedHost = nil
    localSelectedIndex = ""
    indexArray = []
    localFilterObject.clear()
//    withAnimation {
      showing = .All
//    }
  }
  
  func selectedHostFunc (_ host:  HostDetails) {
//    withAnimation {
      localSelectedHost = host
      showing = .NewSearch
//    }
    Task {
      await updateIndexArray()
    }
  }
  
  @MainActor
  func updateIndexArray() async {
    
    loadingIndices = true
    indexError = nil
    
    do {
      guard let localSelectedHost = localSelectedHost else {
        indexError = ResponseError(title: "No Host", message: "Select a host to list indices", type: .critical)
        loadingIndices = false
        return
      }
      
      let response = await Indicies.listIndexes(serverDetails: localSelectedHost)
      if let parsed = response.parsed {
        let indexResult = Results.getIndexArray(parsed)
        if let error = indexResult.error {
          indexError = ResponseError(title: "Index Parsing Error", message: error, type: .critical)
        } else {
          indexArray = indexResult.data
          
          
          
          localSelectedIndex = indexArray.isEmpty ? "" : localSelectedIndex
        }
      } else {
        indexError = ResponseError(title: "Response Error", message: "No data received", type: .critical)
      }
    }
    loadingIndices = false
  }
  
  func mappingRequest() async {
    loadingFieldsMapping = true
    if let localSelectedHost = localSelectedHost {
      fields = await IndexMap.indexMappings(serverDetails: localSelectedHost, index: localSelectedIndex)
    }
    loadingFieldsMapping = false
    
  }
  
  @State var toDate : Date = .now
  @State var fromDate : Date = .now
  @State var refreshDatePickers : UUID = UUID()

  @ObservedObject var searchHistoryManager : SearchHistoryDataManager
  
  var body: some View {
    
    ZStack {
      VStack(spacing:5){
        VStack {
          if localSelectedHost == nil {
            macosSearchHomeInitView(localSelectedHost: $localSelectedHost,
                                    localSelectedIndex: $localSelectedIndex,
                                    indexArray: $indexArray,
                                    showing: $showing,
                                    serverObjects: serverObjects, 
                                    sidebar:$sidebar,
                                    selection: $selection, 
                                    updateIndexArray: updateIndexArray,
                                    mappingRequest: mappingRequest,
                                    selectedHostFunc: selectedHostFunc)
          } else {
            macosSearchHomeView(localSelectedHost: $localSelectedHost,
                                localSelectedIndex: $localSelectedIndex,
                                localFilterObject: localFilterObject,
                                indexArray: $indexArray,
                                showing: $showing,
                                request: request,
                                unselectedHost: unselectedHost,
                                fields: $fields,
                                loadingIndices: $loadingIndices,
                                loadingFieldsMapping: $loadingFieldsMapping,
                                indexError: $indexError,
                                updateIndexArray: updateIndexArray,
                                mappingRequest: mappingRequest,
                                selectedHostFunc: selectedHostFunc,
                                selection:$selection,
                                refreshDatePickers: $refreshDatePickers,
                                relativeCustomdatePeriod:$relativeCustomdatePeriod,
                                serverObjects: serverObjects,
                                sidebar:$sidebar)
          }
        }
        .padding(10)
        .background(Color("BackgroundFixedShadow"))
        .clipShape(.rect(cornerRadius: 5))
        .padding(.top, fullScreen ? 5 : 0)
        
        VStack {
          macosSearchHistoryView(serverObjects: serverObjects,
                                 showing:$showing,
                                 searchHistoryManager: searchHistoryManager,
                                 request:request)
        }
        .padding(10)
        .background(Color("BackgroundFixedShadow"))
        .clipShape(.rect(cornerRadius: 5))
        
      }
      .padding(.leading, 3)
      .padding(.trailing, 5)
      .padding(.bottom, 5)
      // TODO fix dates reseting to NOW
      .onChange(of: localFilterObject.absoluteRange?.from) { newValue in
        fromDate = localFilterObject.absoluteRange?.from ?? Date.now
      }
      .onChange(of: localFilterObject.absoluteRange?.to) { newValue in
        toDate = localFilterObject.absoluteRange?.to ?? Date.now
      }
      
      if selection != .None {
        RoundedRectangle(cornerRadius: 5).fill(Color.black).opacity(0.4)
          .frame(maxWidth: .infinity, alignment: .leading)
          .frame(maxHeight: .infinity)
          .contentShape(Rectangle())
          .onTapGesture {
            selection = .None
          }
          .padding(.leading, 3)
          .padding(.trailing, 5)
        
        if selection == .NewSearchDatePickerFrom {
          VStack(alignment: .leading) {
            HStack {
              macosAbsoluteCalendarWrapperView(selectedDate: $fromDate, cornerRadius: (5,5,5,5))
                .frame(maxWidth: 400)
                .onChange(of: fromDate) { newValue in
                  localFilterObject.relativeRange = nil
                  
                  if localFilterObject.absoluteRange == nil {
                    localFilterObject.absoluteRange = AbsoluteDateRangeObject(from: newValue, to:Date.now)
                  } else {
                    localFilterObject.absoluteRange?.from = newValue
                  }
                  refreshDatePickers = UUID()
                }
              Spacer()
            }
            .padding(.top, 290)
            .padding(.leading, 16)
            Spacer()
          }
        } else if selection == .NewSearchDatePickerTo {
          VStack(alignment: .leading) {
            HStack {
              macosAbsoluteCalendarWrapperView(selectedDate: $toDate, cornerRadius: (5,5,5,5))
                .frame(maxWidth: 400)
                .onChange(of: toDate) { newValue in
                  localFilterObject.relativeRange = nil
                  if localFilterObject.absoluteRange == nil {
                    localFilterObject.absoluteRange = AbsoluteDateRangeObject(from: Date.now, to:newValue)
                  } else {
                    localFilterObject.absoluteRange?.to = newValue
                  }
                  refreshDatePickers = UUID()

                }
              Spacer()
            }
            .padding(.top, 290)
            .padding(.leading, 160)
            Spacer()
          }
        } else if selection == .NewSearchFieldPicker {
          VStack(alignment: .leading) {
            Text("Sorting - Fields List")
              .frame(maxWidth: .infinity)
              .padding(10)
              .background(Color("BackgroundAlt"))
            ScrollView {
              ForEach(fields, id: \.self) { item in
                Button {
                  localFilterObject.sort = SortObject(order: .Descending, field: item)
                  selection = .None
                } label: {
                  Text(item.squashedString)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color("Button"))
                    .clipShape(.rect(cornerRadius: 5))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 5)
              }
            }
          }
          .frame(height: 500)
          .frame(width: 500)
          .background(Color("Background"))
          .clipShape(.rect(cornerRadius: 5))
        } else if selection == .NewSearchRelativeCustomValues {
          VStack(alignment: .leading) {
            HStack {
              VStack {
                ForEach(SearchDateTimePeriods.allCases, id: \.self) { period in
                  macosSearchHomeRelativeCustomButton(title: period.rawValue) {
                    relativeCustomdatePeriod = period
                    selection = .None
                  }
                }
              }
              .padding(10)
              .frame(width: 250)
              .background(Color("Background"))
              .clipShape(.rect(cornerRadius: 5))
              
              Spacer()
            }
            .padding(.top, 290)
            .padding(.leading, 180)
            Spacer()
          }
         
        }
      }
    }
  }
}


struct macosSearchHomeRelativeCustomButton: View {
  let title: String
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Text(title)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color("Button"))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
  }
}
