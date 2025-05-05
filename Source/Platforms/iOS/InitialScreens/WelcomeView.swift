// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct Welcome: View {
  
  enum WelcomeState : String {
    case Loading
    case Welcome
    case Independent
    case LongTime
    case ThankYou
    case Main
  }
  
  @State var state : WelcomeState = .Loading
  
  @AppStorage("showInitialScreen") private var showInitialScreen: Bool = true
  
  func Introduction() {
    var timer = 0.5
    
    DispatchQueue.main.asyncAfter(deadline: .now() + timer) {
      
      withAnimation(Animation.linear(duration: 1)) {
        state = .Welcome
      }
    }
    
    timer=timer+1
    
    DispatchQueue.main.asyncAfter(deadline: .now() + timer) {
      
      withAnimation(Animation.linear(duration: 1)) {
        state = .Loading
      }
    }
    
    timer=timer+1
    
    DispatchQueue.main.asyncAfter(deadline: .now() + timer) {
      showInitialScreen=false
    }
  }
  
  var body: some View {
    VStack {
      
      if state == .Loading {
        
      } else if state == .Welcome {
        VStack {
          Text("Welcome")
            .font(.title)
        }
      } else if state == .Independent {
        VStack(spacing:30) {
          
          Text("I'm Ryan 👋")
            .font(.title)
          Text("Independent Software Developer")
            .font(.system(size: 20))
          
        }.padding(.horizontal, 10)
      }  else if state == .LongTime {
        VStack(spacing:30) {
          
          
          Text("Thank you for downloading Search Ops")
            .font(.system(size: 20))
          
          
        }.padding(.horizontal, 20)
      }
      
    } .multilineTextAlignment(.center)
      .onAppear {
        Introduction()
        
      }
    
  }
}
