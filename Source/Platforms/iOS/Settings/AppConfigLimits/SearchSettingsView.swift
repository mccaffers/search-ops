// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct SearchSettingsView: View {
  
  @EnvironmentObject var settingsManager: SettingsDataManager
  
  @State var showNavigationBar = false
  @State var refresh = UUID()
  
  @State private var selection : Int = 15 // default
  @State private var searchHistory : Int = 0
  @State private var recentHistory : Int = 0
  
  var timeoutOptions : [Int] = [15, 30, 60]
  
  @State var clearSearchHistoryText = "Clear Search History"
  @State var clearSearchHistoryButtonBackground = Color("Button")
  @State var clearSearchHistoryButtonDisabled = false
  
  @ObservedObject var searchHistoryManager : SearchHistoryDataManager
  @ObservedObject var filterHistoryDataManager : FilterHistoryDataManager
  @State private var isCleared = false
  @State private var buttonText = "Clear Recent Searches"
  
  func clearSearchHistoryButtonAction() {
    if !clearSearchHistoryButtonDisabled {
      filterHistoryDataManager.clear()
      filterHistoryDataManager.refresh()
    }
  }
  
  func setLimit(input:Int) {
    settingsManager.setDocumentsPerPage(input:input)
    refresh=UUID()
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack (spacing:15){
          
          
          
          Text("Documents per page")
            .frame(maxWidth: .infinity, alignment:.leading)
            .multilineTextAlignment(.trailing)
            .padding(.top, 5)
          
          
          Text("Maximum amount of documents returned in search request")
            .font(.footnote)
            .foregroundStyle(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment:.leading)
            .multilineTextAlignment(.leading)
          
          VStack {
            HStack {
              Button {
                setLimit(input: 10)
              } label: {
                Text("10")
                  .padding(10)
                  .background(settingsManager.settings?.maximumDocumentsPerPage == 10 ? Color("ButtonHighlighted") : Color("Button"))
                  .foregroundColor(.white)
                  .cornerRadius(5)
              }
              
              Button {
                setLimit(input: 25)
              } label: {
                Text("25")
                  .padding(10)
                  .background(settingsManager.settings?.maximumDocumentsPerPage == 25 ? Color("ButtonHighlighted") : Color("Button"))
                  .foregroundColor(.white)
                  .cornerRadius(5)
              }
              
              Button {
                setLimit(input: 50)
              } label: {
                Text("50")
                  .padding(10)
                  .background(settingsManager.settings?.maximumDocumentsPerPage == 50 ? Color("ButtonHighlighted") : Color("Button"))
                  .foregroundColor(.white)
                  .cornerRadius(5)
              }
            }.frame(maxWidth: .infinity, alignment:.leading)
            
          }
          
          HostAddDivider()
          
          Text("Request Timeout")
            .frame(maxWidth: .infinity, alignment:.leading)
            .multilineTextAlignment(.leading)
          
          Text("The maximum duration a network request is allowed to take before it's considered unsuccessful")
            .font(.footnote)
            .foregroundStyle(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment:.leading)
            .multilineTextAlignment(.leading)
          
          HStack {
            
            Menu {
              ForEach(timeoutOptions, id: \.string) { index in
                Button {
                  selection = index
                } label: {
                  Text(index.string + " seconds")
                }
              }
            }
            label: {
              HStack {
                Text(selection.string + " seconds")
                Image(systemName: "chevron.down")
              }
              .padding(.vertical, 10)
              .frame(maxWidth: .infinity)
              .background(Color("Button"))
              .foregroundColor(.white)
              .cornerRadius(5)
              .onChange(of: selection) { newValue in
                settingsManager.setTimeoiut(input: newValue)
              }
              
            }
            .onChange(of: selection) { newValue in
              print(newValue)
            }
          }
          .padding(.bottom, 5)
          
          HostAddDivider()
          
          Text("Query History")
            .frame(maxWidth: .infinity, alignment:.leading)
            .multilineTextAlignment(.leading)
          
          
          Text("Query history is stored locally, allowing you to quickly repeat past query strings. Navigate to the Filters section on the Search Screen and select History to view your recent searches.")
            .font(.footnote)
            .foregroundStyle(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment:.leading)
            .multilineTextAlignment(.leading)
          
          Text("\(searchHistory) items in Search History")
            .font(.footnote)
            .foregroundStyle(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment:.leading)
            .multilineTextAlignment(.leading)
          
          
          Button(action: {
            clearSearchHistoryText = "Sucess"
            clearSearchHistoryButtonBackground = Color("PositiveButton")
            clearSearchHistoryButtonAction()
            clearSearchHistoryButtonDisabled = true
            
            Task {
              searchHistory =  filterHistoryDataManager.items.count
              
              try await Task.sleep(seconds: 1.5)
              
              withAnimation {
                clearSearchHistoryButtonBackground = Color("Button")
                clearSearchHistoryText = "Clear Search History"
                clearSearchHistoryButtonDisabled = false
              }
            }
          }, label: {
            Text(clearSearchHistoryText)
              .foregroundColor(.white)
              .padding(.vertical, 15)
              .frame(maxWidth: .infinity, alignment: .center)
              .background(clearSearchHistoryButtonBackground)
              .cornerRadius(5.0)
          })
          .disabled(clearSearchHistoryButtonDisabled)
          
          
          
          HostAddDivider()
          
          Text("Recent History")
            .frame(maxWidth: .infinity, alignment:.leading)
            .multilineTextAlignment(.leading)
          
          Text("Recent Search History is stored locally, allowing you to quickly repeat past searches. Navigate to main Search screen and click the \"Recent\" button to see your Search History")
            .font(.footnote)
            .foregroundStyle(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment:.leading)
            .multilineTextAlignment(.leading)
          
          Text("\(recentHistory) items in Search History")
            .font(.footnote)
            .foregroundStyle(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment:.leading)
            .multilineTextAlignment(.leading)
          
          
          
          Button(action: {
            if !isCleared {
              searchHistoryManager.deleteAll()
              searchHistoryManager.refresh()
              recentHistory = searchHistoryManager.items.count
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
              .padding(.vertical, 15)
              .frame(maxWidth: .infinity)
              .background(isCleared ? Color("PositiveButton") : Color("Button"))
              .foregroundColor(.white)
              .clipShape(RoundedRectangle(cornerRadius: 5))
              .animation(.easeInOut(duration: 0.3), value: isCleared)
          }
          .buttonStyle(PlainButtonStyle())
          
          Spacer()
          
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 10)
      }
      .onAppear {
        filterHistoryDataManager.refresh()
        searchHistory = filterHistoryDataManager.items.count
        searchHistoryManager.refresh()
        recentHistory = searchHistoryManager.items.count
      }
      .frame(maxWidth: .infinity)
      .background(Color("Background"))
      .navigationTitle("App Config & Limits")
      .navigationBarTitleDisplayMode(.large)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
      .id(refresh)
    }
    .background(Color("Background"))
  }
}
#endif
