// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SettingsView: View {
  @Environment(\.openURL) var openURL
  @ObservedObject var searchHistoryManager: SearchHistoryDataManager
  @Binding var fullScreen: Bool
  
  @State private var isCleared = false
  @State private var buttonText = "Clear Recent Searches"
  
  let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  
  func emailText() -> AttributedString {
    var message1: AttributedString {
      var result = AttributedString("Please contact me if you have any issues or feedback. You can email me feedback at ")
      result.foregroundColor = Color("TextSecondary")
      
      return result
    }
    
    var message2: AttributedString {
      var result = AttributedString("ryan@mccaffers.com")
      result.foregroundColor = Color("ButtonLight")
      
      return result
    }
    
    let twoatt = message1 + message2
    
    return twoatt
    
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Settings")
          .font(.system(size: 22, weight: .light))
        Spacer()
      }
      .padding(.vertical, 10)
      
      VStack(alignment: .leading, spacing:10 ) {
        
        Button(action: {
          if !isCleared {
            searchHistoryManager.deleteAll()
            withAnimation(.easeInOut(duration: 0.3)) {
              isCleared = true
              buttonText = "Cleared"
            }
            
            // Reset button after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
              withAnimation(.easeInOut(duration: 0.3)) {
                isCleared = false
                buttonText = "Clear Recent Searches"
              }
            }
          }
        }) {
          Text(buttonText)
            .padding(10)
            .frame(minWidth: 200)
            .background(isCleared ? Color("PositiveButton") : Color("Button"))
            .foregroundColor(isCleared ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .animation(.easeInOut(duration: 0.3), value: isCleared)
        }
        .buttonStyle(PlainButtonStyle())
      }.padding(.leading, 10)
      
      HStack {
        Text("Build Details")
          .font(.system(size: 22, weight: .light))
        Spacer()
      }
      .padding(.vertical, 10)
      
      VStack(alignment: .leading, spacing:10 ) {
        
        Text("Version: " + (appVersion ?? ""))
          .frame(maxWidth: .infinity, alignment:.leading)
        
        Text("App: " + (Bundle.main.appHash ?? ""))
          .frame(maxWidth: .infinity, alignment:.leading)
        
        let databaseSize =  RealmManager.checkRealmFileSize()
        Text("Database Size: " +  String(format: "%.2f", databaseSize) + "mb")
          .frame(maxWidth: .infinity, alignment:.leading)
        
      }.padding(.leading, 10)
      
      HStack {
        Text("Privacy")
          .font(.system(size: 22, weight: .light))
        Spacer()
      }
      .padding(.vertical, 10)
      
      VStack(alignment: .leading, spacing:10 ) {
        
        Text("Strictly no analytics, tracking or advertisements in Search Ops!")
          .font(.system(size: 16))
        
        Text("In addition, to increase transparency and build trust for the application, the business logic for Search Ops is available on Github.")
          .frame(maxWidth: .infinity, alignment:.leading)
        
        Text("The repository contains the logic for how the application stores and queries your infrastructure. The build hash aligns with the commit hash on Github")
          .frame(maxWidth: .infinity, alignment:.leading)
        
      }.padding(.leading, 10)
      
      HStack {
        Text("Links")
          .font(.system(size: 22, weight: .light))
        Spacer()
      }
      .padding(.vertical, 10)
      
      VStack(alignment: .leading, spacing:10 ) {
        Text("Business Logic Codebase on Github https://github.com/mccaffers/search-ops")

          .frame(maxWidth: .infinity, alignment:.leading)
     
        
        Text("Privacy Policy on https://searchops.app")

          .frame(maxWidth: .infinity, alignment:.leading)
   
          
        
        
      }.padding(.leading, 10)
      
      HStack {
        Text("Feedback")
          .font(.system(size: 22, weight: .light))
        Spacer()
      }
      .padding(.vertical, 10)
      
      VStack(alignment: .leading, spacing:10 ) {
        
        Text("Thanks for purchasing Search Ops!")
        
        Link(destination: URL(string: "mailto:ryan@mccaffers.com")!) {
          
          Text(emailText()) //.map { Text("\($0) ") }.reduce(Text(""), +)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
        }.frame(maxWidth: .infinity, alignment: .leading)
        
      }.padding(.leading, 10)
      Spacer()
      
    }
    .padding(.horizontal, 10)
    .foregroundColor(Color("TextSecondary"))
    .background(Color("BackgroundFixedShadow"))
    .clipShape(RoundedRectangle(cornerRadius: 5))
    .padding(.leading, 3)
    .padding(.trailing, 5)
    .padding(.bottom, 5)
    .padding(.top, fullScreen ? 5 : 0)
  }
}
