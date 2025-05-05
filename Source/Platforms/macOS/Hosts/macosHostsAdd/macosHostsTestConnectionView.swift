// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosHostsTestConnectionView : View {
  
  @Binding var currentView: macosHostsAddViewEnum
  
  var item : HostDetails
  @State var loading = true
  @State var response : ServerResponse?
  
  @MainActor
  func queryElastic() async {
    
//    guard let item = host else { return }
    
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
    VStack {
      
      VStack(
        alignment: .leading,
        spacing: 10
      )  {
        
        VStack(alignment: .leading) {
          HStack (spacing:5) {
            Image(systemName: "arrow.right")
            Text("Request")
           
            Spacer()
            Text("GET")
          }
          .font(.system(size: 14))
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 15)
        .background(Color("BackgroundFixedShadow"))
        
        
        VStack(spacing:10) {
          if loading {
            HStack {
              ProgressView().scaleEffect(0.8)
              Text("Requesting")
            }
          } else if let error = response?.error {
            Text(error.message)
              .foregroundColor(.red)
          } else {
            Text(response?.url?.absoluteString ?? "")
            
          }
        }
        .font(.system(size: 14))
        .padding(.horizontal, 10)
        
        
        VStack(alignment: .leading) {
          HStack (spacing:5) {
            Image(systemName: "arrow.left")
            Text("Response")
            
            Spacer()
            
            if let status = response?.httpStatus {
              Text(status.string)
                .font(.system(size: 14))
                .foregroundColor(HTTPStatusColors.getStatusColor(input: status))
            }
            
          }
          .font(.system(size: 14))
          .foregroundColor(Color("TextColor"))
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 15)
        .background(Color("BackgroundFixedShadow"))
        
        
        
        VStack {
          //            if response != "error" {
          Text(response?.parsed ?? "")
            .font(.system(size: 14))
          //            }
        }.padding(.horizontal, 10)
        
      }
      
      Button {
        withAnimation {
          currentView = .main
        }
      } label: {
        HStack {
          Image(systemName: "arrow.left")
          Text("Back")
        }
          .padding(10)
          .background(Color("Button"))
          .clipShape(.rect(cornerRadius: 5))
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding(.bottom, 10)
    .onAppear {
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        Task {
          await queryElastic()
        }
      }
      
    }
  }
}
