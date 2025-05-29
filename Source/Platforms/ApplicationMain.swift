// SearchOps Source Code
// Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

@main
struct ApplicationMain: App {
  
  
  // Default dark mode
  @AppStorage("appearanceSelection") private var appearanceSelection: Int = 2
  
  var appearanceSwitch: ColorScheme? {
    if appearanceSelection == 1 {
      return .light
    }
    else if appearanceSelection == 2 {
      return .dark
    }
    else {
      return .none
    }
  }
  
  init(){
    print("Current Bundle Commit:" + (Bundle.main.appHash ?? "undefined"))
  }
  
  
   
  static func isValidBundleID() -> Bool {
       guard let bundleID = Bundle.main.bundleIdentifier else {
           return false
       }
       
      return bundleID == Bundle.myBundleID
   }
  
  var body: some Scene {
    WindowGroup {
      if !ApplicationMain.isValidBundleID() {
        PoliteNoticeView()
      } else {
#if os(iOS)
        ContentView()
          .preferredColorScheme(appearanceSwitch)
          .edgesIgnoringSafeArea(.all)
#elseif os(macOS)
        ContentViewMacOS()
          .frame(minWidth: 1200, maxWidth: .infinity, minHeight: 800, maxHeight: .infinity)
#endif
      }
    }
#if os(macOS)
    .windowStyle(HiddenTitleBarWindowStyle()) // Apply the hidden title bar style
#endif
    
  }
}

struct PoliteNoticeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "figure.wave")
                .font(.system(size: 60))
                .foregroundColor(.black)
            
            Text("Polite Notice")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("I ask kindly that you do not simply reupload the open source project directly on to the App Store.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Thanks very much, Ryan")
                .font(.subheadline)
                .padding(.top, 10)
          
          Text("ryan@mccaffers.com")
              .font(.subheadline)
              .padding(.top, 10)
            
            Spacer()
        }
        .padding()
    }
}

extension Data {
    var prettyJson: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding:.utf8) else { return nil }

        return prettyPrintedString
    }
}




extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
