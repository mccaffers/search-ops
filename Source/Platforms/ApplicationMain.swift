// SearchOps Source Code
// Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

#if os(macOS)
import AppKit
#endif

@main
struct ApplicationMain: App {
  
  init(){
    print("Current Bundle Commit:" + (Bundle.main.appHash ?? "undefined"))
#if os(macOS)
    NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
#endif
  }
  
  static func isValidBundleID() -> Bool {
       guard let bundleID = Bundle.main.bundleIdentifier else {
           return false
       }
       
      return bundleID == Bundle.myBundleID
   }
  
  var body: some Scene {
    WindowGroup {
      Group {
        if !ApplicationMain.isValidBundleID() {
          PoliteNoticeView()
        } else {
#if os(iOS)
          ContentView()
            .edgesIgnoringSafeArea(.all)
#elseif os(macOS)
          ContentViewMacOS()
            .frame(minWidth: 700, idealWidth: 1200, maxWidth: .infinity, minHeight: 500, idealHeight: 800, maxHeight: .infinity)
#endif
        }
      }
      .preferredColorScheme(.dark)
#if os(macOS)
      .onAppear {
        NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
      }
#endif
    }
#if os(macOS)
    .windowStyle(HiddenTitleBarWindowStyle()) // Apply the hidden title bar style
    .defaultSize(width: 1200, height: 800)
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
