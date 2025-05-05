// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct SettingsApplicationLogsView: View {
  
  @State var logs : [String] = []
  @State private var showAlert = false  // State to control the alert visibility
  
  var body: some View {
    VStack (spacing:0) {
      
      Text("The application logs offer insights into the app's internal operations. While you don't need to take any action with this information, it can be useful for troubleshooting if you encounter any issues.")
        .font(.subheadline)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .padding(.top, 10)
      
      if logs.isEmpty {

        Text("No application logs at the moment")
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 20)
        Spacer()
      } else {
        
        Text("Log Files")
            .font(.footnote)
            .foregroundColor(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 5)
            .padding(.bottom, 5)
        
        List(logs, id: \.self) { item in
          NavigationLink(destination: AppLogDetailsView(myTitle: item)) {
            Text(item)
              .foregroundStyle(Color("ButtonText"))
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading) // Expand frame
              .contentShape(Rectangle()) // Important for clickability across the entire expanded area
              .padding(.vertical, 8) // Add some vertical padding for better visuals
              .background(Color("Button")) // Apply the background color to the Text view
              .listRowInsets(EdgeInsets()) // Remove default paddingr
          }
          .padding(.horizontal, 20) // Add some vertical padding for better visuals
          .listRowInsets(EdgeInsets()) // Remove default padding
         .background(Color("Button")) // Set background color here for full-width effect
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
        
        Text("Logs are stored locally on your device in a temproary directory. The directory is cleared automatically.")
          .font(.footnote)
          .foregroundColor(Color("TextSecondary"))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 15)
          .padding(.bottom, 10)
      }
      
    }
    .onAppear {
      SystemLogger().flush()
      logs = SystemLogger().listFiles().sorted { $0 > $1}
    }
    .toolbar {
      // Define toolbar items
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: {
          showAlert = true  // Show the alert when the button is pressed
        }) {
          Image(systemName: "trash")
        }
      }
    }
    .alert("Delete all logs", isPresented: $showAlert) {
      // Define the buttons and actions for the alert
      Button("Yes", role: .destructive) {
        SystemLogger().clearLogs()
        logs=[]
      }
      Button("No", role: .cancel) {
        //
      }
    } message: {
      //Text("Would you like to delete all your application logs?")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color("Background"))
    .navigationTitle("Application Logs")
    .navigationBarTitleDisplayMode(.large)
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
  }
}



#Preview {
    SettingsApplicationLogsView()
}

#endif
