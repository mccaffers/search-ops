// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import RealmSwift

#if os(iOS)
struct TestingConnectionView: View {
  
  var item: HostDetails
  @State private var response : ServerResponse?
  @State private var responseCode = 0
  @State private var loading = true
  
  func statusColor(_ input: String) -> Color {
    if input == "unsupported URL" {
      return .red
    } else {
      return Color("Divider")
    }
  }
  
  @MainActor
  func queryElastic() async {
    
    response = await Search.testHost(serverDetails: item)
    loading = false
    
    if let parsed = response?.parsed {
      
      let json = JsonTools.serialiseJson(parsed)
      
      if let dictionary = json  {
        if let versionObj = dictionary["version"] as? [String: Any] {
          if let versionString = versionObj["number"] as? String {
            
            HostsDataManager.setVersion(item: item, version: versionString)
            
          }
        }
        
      }
      
    }
    
  }
  
  var body: some View {
    
    ZStack {
      
      ScrollView{
        
        VStack(
          alignment: .leading,
          spacing: 10
        )  {
          
          VStack(alignment: .leading) {
            HStack (spacing:5) {
              Image(systemName: "arrow.right")
              Text("Request")
              if loading {
                ProgressView()
              }
              Spacer()
              Text("GET")
            }
            .font(.system(size: 16, weight:.regular))
            .foregroundColor(Color("TextColor"))
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 15)
          .background(Color("BackgroundAlt"))
          
          
          VStack(spacing:10) {
            if let error = response?.error {
              Text(error.message)
                .font(.system(size: 16, weight: .light, design: .rounded))
                .monospaced()
                .foregroundColor(.red)
            } else {
              Text(response?.url?.absoluteString ?? "")
                .font(.system(size: 16, weight: .light, design: .rounded))
                .monospaced()
                .textSelection(.enabled)
              
            }
          }.padding(.horizontal, 10)
          
          
          VStack(alignment: .leading) {
            HStack (spacing:5) {
              Image(systemName: "arrow.left")
              Text("Response")
              
              Spacer()
              
              if let status = response?.httpStatus {
                Text(status.string)
                  .font(.system(size: 16, weight: .light, design: .rounded))
                  .foregroundColor(HTTPStatusColors.getStatusColor(input: status))
              }
              
            }
            .font(.system(size: 16, weight:.regular))
            .foregroundColor(Color("TextColor"))
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 15)
          .background(Color("BackgroundAlt"))
          
          
          
          VStack {
            //						if response != "error" {
            Text(response?.parsed ?? "")
              .font(.system(size: 16, weight: .regular, design: .rounded))
              .monospaced()
              .foregroundColor(Color("TextColor"))
            //						}
          }.padding(.horizontal, 10)
          
          Spacer()
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Background"))
    .navigationTitle("Connection Test")
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
    .onAppear {
      Task { @MainActor in
        await queryElastic()
      }
      
    }
    
    
  }
}
#endif
