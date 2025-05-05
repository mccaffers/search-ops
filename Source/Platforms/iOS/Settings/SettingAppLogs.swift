// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

import SwiftyJSON

struct JSONResponse {
	public var contents : String = ""
	public var error : Bool = false
}

struct SettingAppLogs: View {
  @StateObject var logManager = LogDataManager()
  
  @State var showNavigationBar = false
  @State var showingRequestJson = false
  @State var event : LogEvent? = nil
  
  static func render(input:String) async -> JSONResponse {
    
    var responseObject = JSONResponse()
    
    if input.count > 100000 {
      let byteCount = input.data.count // replace with data.count
      let bcf = ByteCountFormatter()
      bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
      bcf.countStyle = .file
      let string = bcf.string(fromByteCount: Int64(byteCount))
      //			let response =
      responseObject.contents = ("Sorry! Unable to render JSON response as it's too large (" + string + ")")
      responseObject.error = true
      
      
      //			return "Response too big to render in app" String(input.prefix(100000))
    } else if let jsonResponse = JSON(input.data(using: .utf8)).rawString(options:[.sortedKeys, .withoutEscapingSlashes, .prettyPrinted]),
              jsonResponse != "null" {
      responseObject.contents = jsonResponse
      //      responseObject
      
    } else {
      responseObject.contents = input
      
    }
    
    return responseObject
  }
  
  var body: some View {
    VStack {
      
      if logManager.items.count > 0 {
        List {
          
          let myList = logManager.items.sorted {$0.date > $1.date }
          ForEach(myList.indices, id:\.self) { index in
            
            HStack (spacing:5){
              
              Text(DateTools.buildDateLarge(input: myList[index].date))
                .foregroundColor(Color("TextSecondary"))
              
              
              Spacer()
              
              let status = myList[index].httpStatus
              if let error = myList[index].error?.title {
                Text(error)
                  .foregroundColor(.red)
              }
              else if status >= 200 && status < 400 {
                Text(myList[index].httpStatus.string)
                  .foregroundColor(Color("PositiveButton"))
              } else {
                Text(myList[index].httpStatus.string)
                  .foregroundColor(.red)
              }
            }
            .font(.system(size:14))
            .padding(.vertical, 5)
            .padding(.top, index == 0 ? 5 : 0)
            .frame(maxWidth: .infinity, alignment:.leading)
            .padding(.horizontal, 15)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color("Background"))
            .listRowSeparator(.hidden)
            
            
            Button {
              event = myList[index]
              showingRequestJson = true
            } label: {
              HStack {
                VStack(alignment: .leading, spacing:10) {
                  
                  let path = myList[index].host?.host?.path ?? ""
                  
                  if path.isEmpty {
                    HStack (spacing:3) {
                      Image(systemName: "info.square")
                        .font(.system(size: 16, weight:.light))
                        .padding(.horizontal, 2)
                      
                      Text("Connection Test")
                      
                      Spacer()
                      
                    }
                    
                    HStack (spacing:3) {
                      
                      HStack {
                        Image(systemName: "server.rack")
                          .font(.system(size: 16, weight:.light))
                        
                        Text(myList[index].host?.name ?? "")
                          .truncationMode(.head)
                          .lineLimit(1)
                        
                      }.padding(.trailing, 10)
                      
                      HStack {
                        Image(systemName: "link")
                          .font(.system(size: 16, weight:.light))
                        
                        
                        Text("/")
                        
                        
                        
                      }.padding(.trailing, 10)
                      
                    }
                    
                  } else {
                    HStack (spacing:3) {
                      Image(systemName: "link")
                        .font(.system(size: 16, weight:.light))
                      
                      
                      Text(path)
                      
                      
                      Spacer()
                      
                    }
                    
                  }
                  
                  if path.contains("_search") {
                    
                    HStack (spacing:10) {
                      HStack (spacing:3) {
                        Image(systemName: "doc.on.doc")
                          .font(.system(size: 16, weight:.light))
                        
                        Text(myList[index].hitCount.string + " docs")
                      }
                      
                      HStack (spacing:3) {
                        Image(systemName: "scroll")
                          .font(.system(size: 16, weight:.light))
                        
                        let page = myList[index].page
                        if page == 0 {
                          Text("page 1")
                        } else {
                          Text("page " + page.string)
                        }
                      }
                      Spacer()
                      
                    }
                  }
                  
                  if path.contains("_mapping") {
                    
                    HStack (spacing:10) {
                      HStack (spacing:3) {
                        Image(systemName: "doc.on.doc")
                          .font(.system(size: 16, weight:.light))
                        
                        Text(myList[index].hitCount.string + " fields")
                      }
                      
                      
                      
                    }
                    
                    
                  }
                  
                  
                }
                .foregroundColor(Color("TextColor"))
                .font(.system(size: 15))
                Spacer()
                Image(systemName: "chevron.right")
                  .font(.system(size: 24))
                  .foregroundColor(Color("LabelBackgrounds"))
                
              }
              .padding(.horizontal, 15)
              .padding(.vertical, 15)
              //
              //							Rectangle().fill(Color("LabelBackgrounds"))
              //								.frame(maxWidth: .infinity)
              //								.frame(height: 2)
              
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .frame(maxWidth: .infinity, alignment:.leading)
            //						.padding(.top, 10)
            .background(Color("HeaderTitleBackground"))
            .cornerRadius(5)
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
          }
        }.listStyle(.plain)
          .environment(\.defaultMinListRowHeight, 12)    // << D
      } else {
        Spacer()
        Text("No log entries!")
          .frame(maxWidth: .infinity, alignment:.center)
          .padding(.vertical, 20)
        Spacer()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Background"))
    .navigationTitle("Request Logs")
#if os(iOS)
    .navigationBarTitleDisplayMode(.large)
#endif
    .onAppear {
      logManager.refresh()
      //			withAnimation(Animation.linear(duration:0)) {
      //				showNavigationBar = true
      //			}
    }
    //		.toolbar(showNavigationBar ? .visible : .hidden, for:.navigationBar)
#if os(iOS)
    .toolbarBackground(Color("TabBarColor"), for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
    .toolbar {
      if logManager.items.count > 0 {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Clear") {
            logManager.deleteAll()
          }
          .tint(Color("TextColor"))
          .foregroundColor(Color("TextColor"))
        }
      }
    }
#endif
    .navigationDestination(isPresented:$showingRequestJson, destination: {
      if let event = event {
        SettingsDetailMainView(event:event)
      }
    })
  }
}
