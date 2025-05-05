// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

import SwiftyJSON

struct SettingsDetailMainView: View {
  
  var event : LogEvent
  
  @State var jsonRequest = ""
  
  var body: some View {
    ScrollView {
      VStack(alignment:.leading) {
        
        SettingsDetailHostInformationView(hostname: event.host?.name ?? "",
                                          environment: event.host?.env ?? "",
                                          datefield: event.filter?.dateField?.squashedString ?? "",
                                          index:event.index)
        
        
        VStack {
          HStack {
            Text("HTTP Request")
              .foregroundColor(Color("TextColor"))
              .padding(.vertical, 10)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 15)
        }
        .padding(.vertical, 10)
        .background(Color("BackgroundAlt"))
        
        VStack(spacing:10) {
          
          
          HStack(spacing:10) {
            Text("Scheme")
              .frame(width: 120, alignment: .trailing)
            Text(event.host?.host?.scheme.rawValue ?? "")
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          
          HStack(spacing:10) {
            Text("Host")
              .frame(width: 120, alignment: .trailing)
            Text(event.host?.host?.url ?? "")
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          
          let path = event.host?.host?.path ?? ""
          if !path.isEmpty {
            HStack(spacing:10) {
              Text("Path")
                .frame(width: 120, alignment: .trailing)
              Text(path)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
          }
          
          HStack(spacing:10) {
            Text("Method")
              .frame(width: 120, alignment: .trailing)
            Text(event.method)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          
          
        }
        
        
        SettingsDetailHTTPResponse(status:event.httpStatus,
                                   duration: event.duration.string,
                                   error: event.error)
        
        
        if !event.jsonReq.isEmpty {
          SettingDetailJsonResponseView(title:"HTTP Request Body",
                                        input:event.jsonReq,
                                        index: event.index)
        }
        
        
        if !event.jsonRes.isEmpty {
          if event.index == "_all!" {
            
            SettingsDetailEmptyView(title: "HTTP Response Body")
          } else {
            SettingDetailJsonResponseView(title:"HTTP Response Body",
                                          input:event.jsonRes,
                                          index: event.index)
          }
        }
      }
      
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Background"))
    .navigationTitle("Log Event")
  }
}
