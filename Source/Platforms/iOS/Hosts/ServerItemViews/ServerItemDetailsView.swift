// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct ServerItemDetailsView: View {
  
  var item: HostDetails
  
  @State var showingAlert: Bool = false
  
  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 10
    ) {
      
        HStack {
          Text("Environment: ")
            .frame(minWidth: 100, alignment: .trailing)
          Text(item.env)
          Spacer()
        }.padding(.leading, 15)
        
        HStack {
          Text("Created: ")
            .frame(minWidth: 100, alignment: .trailing)
          Text(item.createdDate.formatted(date: .long, time: .shortened))
          Spacer()
        }.padding(.leading, 15)
        
        if item.connectionType == ConnectionType.CloudID {
          HStack {
            Text("Service: ")
              .frame(minWidth: 100, alignment: .trailing)
            Text("elastic.co")
            Spacer()
          }.padding(.leading, 15)
        }
        
        if item.connectionType == ConnectionType.URL {
          if let host = item.host {
            if(host.url.contains("elastic-cloud.com")) {
              HStack {
                Text("Provider: ")
                  .frame(minWidth: 100, alignment: .trailing)
                Text("elastic.co")
                Spacer()
              }.padding(.leading, 15)
            } else {
              HStack {
                Text("Host: ")
                  .frame(minWidth: 100, alignment: .trailing)
                Text(item.host?.url.string ?? "")
                Spacer()
              }.padding(.leading, 15)
            }
          }
          
        }
        
        HStack {
          Text("Verison: ")
            .frame(minWidth: 100, alignment: .trailing)
          
          if(item.version == ""){
            Button {
              showingAlert=true
            } label: {
              Image(systemName: "questionmark.square.fill")
            }
          } else {
            Text(item.version)
          }
          
          Spacer()
        }
        .padding(.leading, 15)
        .alert("Test the connection to populate version", isPresented: $showingAlert) {
          Button("Okay", role: .cancel) { }
        }
 
    }.foregroundColor(Color("TextColor"))
      .font(.system(size: 16))
      .padding(.vertical, 10)
  }
}
