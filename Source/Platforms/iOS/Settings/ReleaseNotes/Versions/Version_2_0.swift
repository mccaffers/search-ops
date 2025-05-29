// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)

struct GradientButtonView: View {
  var title: String
  var height: CGFloat = 80
  var horizontalPadding: CGFloat = 10
  var cornerRadius: CGFloat = 5
  var borderGradient: LinearGradient = LinearGradient(colors: [Color("LabelBackgroundBorder"), Color("InactiveButtonColor")], startPoint: .trailing, endPoint: .leading)
  var backgroundGradient: LinearGradient = LinearGradient(colors: [Color("Button"), Color("ButtonHighlighted")], startPoint: .trailing, endPoint: .leading)
  
  
  var body: some View {
    Text(title)
      .foregroundStyle(LinearGradient(colors: [Color("LabelBackgroundBorder"),  Color("Purple")], startPoint: .bottomTrailing, endPoint: .topLeading))
      .bold()
      .font(.system(size: 19))
      .frame(height: height)
      .padding(.horizontal, horizontalPadding)
      .frame(maxWidth: .infinity)
      .background(Color("BackgroundAlt"))
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .multilineTextAlignment(.center)
  }
}

struct Version_2_0: View {
  
  var showContinueButton : Bool = false
  var title = "Version 2.0"
  
  var animateDuration : TimeInterval = 0.8
  @State private var showFireworks = false
  @State private var showText = false
  @State private var isVisible = true
  @State private var opacity = 1.0
  @EnvironmentObject var fireworkSettings : FireworkSettings
  
  var body: some View {
    
    ZStack {
      NavigationStack {
        ScrollView {
          VStack (spacing:0) {

            VStack(alignment: .leading, spacing:5) {
              VStack(alignment:.leading, spacing:10) {
                
                HStack {
                  Text("New Features")
                    .foregroundStyle(LinearGradient(colors: [Color("LabelBackgroundBorder"), .purple], startPoint: .trailing, endPoint: .leading))
                    .font(.system(size: 26))
                  Spacer()
                  Text("iOS")
                    .foregroundStyle(LinearGradient(colors: [Color("LabelBackgroundBorder"), .purple], startPoint: .trailing, endPoint: .leading))
                    .font(.system(size: 26))
                }
                
                .frame(maxWidth: .infinity, alignment: .leading)
                .bold()
                .padding(.top, 10)
                
                VStack(alignment:.leading, spacing:15) {
                  VStack(alignment:.leading, spacing:5) {
                    Text("Recent Searches")
                      .font(.system(size: 18))
                      .bold()
                    Text("Searches are saved, allowing you to quickly return to a previous search. A view appears when you launch the app to jump back in.")
                      .padding(.bottom, 10)
                    
                    Image("recent_searches_ios")
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(maxWidth: 400)
                      .padding(2)
                      .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                          .stroke(LinearGradient(colors: [Color("LabelBackgroundBorder"),  Color("Purple")], startPoint: .bottomTrailing, endPoint: .topLeading), lineWidth: 2)
                      )
                  }
                  
                  VStack(alignment:.leading, spacing:5) {
                    Text("Refresh Timer")
                      .font(.system(size: 18))
                      .bold()
                    Text("Set a timer to refresh your search at a set frequency (1 second, 5 seconds, etc.)")
                      .padding(.bottom, 10)
                    
                    Image("ios_timer")
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(maxWidth: 400)
                      .padding(2)
                      .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                          .stroke(LinearGradient(colors: [Color("LabelBackgroundBorder"),  Color("Purple")], startPoint: .bottomTrailing, endPoint: .topLeading), lineWidth: 2)
                      )
                  }
                  
                  VStack(alignment:.leading, spacing:5) {
                    Text("Default Date Range")
                      .font(.system(size: 18))
                      .bold()
                    Text("Refactored the UI to move the Date Field and Date Range next to each other, and if there is only one date field, to select it, and default to the last 15 minutes. I'll make these defaults configurable in a future update!")
                      .padding(.bottom, 10)
                    
                    Image("ios_date_range")
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(maxWidth: 400)
                      .padding(2)
                      .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                          .stroke(LinearGradient(colors: [Color("LabelBackgroundBorder"),  Color("Purple")], startPoint: .bottomTrailing, endPoint: .topLeading), lineWidth: 2)
                      )
                  }
                }
                
              }.padding(.top, 5)
              
              HostAddDivider()
                .padding(.vertical, 10)
              
              VStack(alignment:.leading, spacing:10) {
                
                HStack {
                  Text("New Platform")
                    .foregroundStyle(LinearGradient(colors: [Color("LabelBackgroundBorder"), .purple], startPoint: .trailing, endPoint: .leading))
                    .font(.system(size: 26))
                  Spacer()
                  Text("macOS")
                    .foregroundStyle(LinearGradient(colors: [Color("LabelBackgroundBorder"), .purple], startPoint: .trailing, endPoint: .leading))
                    .font(.system(size: 26))
                  
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .bold()
                
                Text("Developed a native macOS version of SearchOps to complement the iOS app")
                
                Text("Build queries, view recent searches and more on macOS. One Application on multiple platforms (iPhone, iPad and now macOS)")
                
                  .frame(maxWidth: .infinity, alignment: .leading)
                
                Image("macos_front_srceen")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .padding(2)
                  .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                      .stroke(LinearGradient(colors: [Color("LabelBackgroundBorder"),  Color("Purple")], startPoint: .bottomTrailing, endPoint: .topLeading), lineWidth: 2)
                  )
                  .padding(.top, 5)
                
                Image("macos_main_search")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .padding(2)
                  .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                      .stroke(LinearGradient(colors: [Color("LabelBackgroundBorder"),  Color("Purple")], startPoint: .bottomTrailing, endPoint: .topLeading), lineWidth: 2)
                  )
                  .padding(.top, 5)
                
                Image("macos_doc")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .padding(2)
                  .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                      .stroke(LinearGradient(colors: [Color("LabelBackgroundBorder"),  Color("Purple")], startPoint: .bottomTrailing, endPoint: .topLeading), lineWidth: 2)
                  )
                  .padding(.top, 5)

              }
              
              HostAddDivider()
                .padding(.vertical, 10)
              
//              Text("Thank you for purchasing SearchOps!")
//                .padding(.bottom, 10)
              
              Text("More updates to follow!")
                .padding(.bottom, 15)
              
              VStack(alignment: .leading,spacing:10) {
                HStack {
                  GradientButtonView(title: "iPhone & iPad")
                  GradientButtonView(title: "macOS")
                }
                
                HStack {
                  GradientButtonView(title: "No Tracking or Analytics")
                  GradientButtonView(title: "No In App Purchases")
                }
                
              }.padding(.bottom, 15)
              
              Text("Do send feedback to me, my email address is in App Settings")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
              
              
              Spacer()
              
            }
            .padding(.horizontal, 20)
            
          }
        }
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Text("Sept 2024")
              .foregroundColor(Color("TextSecondary"))
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
        
        .background(Color("Background").edgesIgnoringSafeArea(.all))
        
        .frame(maxWidth: .infinity)
        .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {  // Delay of 2 seconds
            
            if !showContinueButton && !showFireworks {
              fireworkSettings.showFireworks = true
            }
            showFireworks = true
            
          }
          
          
        }
      }
      
      
      if showContinueButton {
        FireworksView()
          .edgesIgnoringSafeArea(.all)
          .onAppear {
            // Delay of 5 seconds before starting the fade out animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
              withAnimation(.easeOut(duration: 1.5)) {
                self.opacity = 0.0
              }
              // Delay the hiding of the element to allow the animation to complete
              DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isVisible = false
              }
            }
          }
          .opacity(opacity)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .edgesIgnoringSafeArea(.all)
          .ignoresSafeArea(.all)
          .isHidden(!isVisible)
          .zIndex(0)
      }
      
    }
  }
}
#endif
