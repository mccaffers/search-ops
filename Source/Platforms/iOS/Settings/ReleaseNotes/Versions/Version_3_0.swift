// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct Version_3_0: View {
  
  var showContinueButton : Bool = false
  var title = "Version 3.0"
  
  var animateDuration : TimeInterval = 0.8
  @State private var showFireworks = false
  @State private var showText = false
  @State private var isVisible = true
  @State private var opacity = 1.0
  @EnvironmentObject var fireworkSettings : FireworkSettings
  @EnvironmentObject var orientation : Orientation
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    
    ZStack {
      NavigationStack {
        ScrollView {
          VStack (spacing:0) {
            
            VStack(alignment: .leading, spacing:5) {
              VStack(alignment:.leading, spacing:10) {
                
                HStack {
                  Text("Open Source")
                    .foregroundStyle(LinearGradient(colors: [Color("LabelBackgroundBorder"), .purple], startPoint: .trailing, endPoint: .leading))
                    .font(.system(size: 26))
                  Spacer()
                  
                }
                
                .frame(maxWidth: .infinity, alignment: .leading)
                .bold()
                .padding(.top, 10)
                
                VStack(alignment:.leading, spacing:15) {
                  VStack(alignment:.leading, spacing:5) {
                    Text("Search Ops is now completely Open Source, available to see the entire application on Github with a Convenience Pricing Model.")
                      .padding(.bottom, 10)
                    
                    Image("github_repo")
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(maxWidth: 400)
                      .padding(2)
                      .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                          .stroke(LinearGradient(colors: [Color("LabelBackgroundBorder"),  Color("Purple")], startPoint: .bottomTrailing, endPoint: .topLeading), lineWidth: 2)
                      )
                      .padding(.bottom, 10)
                    Text("You can view all of the code on github.com/mccaffers/search-ops")
                      .padding(.bottom, 10)
                    
                    Text("The application is now trialing a **Convenience Pricing Model**")
                      .padding(.bottom, 10)
                    
                    Text("Source code is open and free on Github. Users can pay a one time small fee (a few pounds/dollars) to skip the hassle of compiling and installing from source by getting through the App Store with automatic updates. This provides insight into the underlying codebase and supports further development, thank you!")
                      .padding(.bottom, 10)
                    
                  }
                }.padding(.top, 5)
                
              }
              
              HostAddDivider()
                .padding(.vertical, 10)
              
              VStack(alignment: .leading,spacing:10) {
                HStack {
                  GradientButtonView(title: "iPhone & iPad")
                  GradientButtonView(title: "macOS")
                }
                
                HStack {
                  GradientButtonView(title: "No Tracking or Analytics")
                  GradientButtonView(title: "Open Source")
                }
                
              }
              
              if showContinueButton {
                
                HostAddDivider()
                  .padding(.vertical, 10)
                
                if !orientation.isLandscape {
                  
                  VStack {
                    Image(systemName: "hand.draw")
                    Text("Swipe down to close")
                  }
                  .frame(maxWidth: .infinity)
                  .font(.footnote)
                  .foregroundStyle(Color("TextSecondary"))
                  .padding(.bottom, 10)
                } else {
                  Button {
                    dismiss()
                  } label: {
                    Text("Continue")
                      .font(.system(size: 20))
                      .foregroundColor(.white)
                      .padding(.vertical, 15)
                      .frame(maxWidth: .infinity)
                      .background(Color("Button"))
                      .cornerRadius(5)
                  }
                  .frame(maxWidth: .infinity, alignment: .center)
                  .padding(.bottom, 20)
                }
              }
              
              
              Spacer()
              
            }
            .padding(.horizontal, 20)
            
          }
        }
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Text("June 2025")
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
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {  // Delay of 2 seconds
            
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
