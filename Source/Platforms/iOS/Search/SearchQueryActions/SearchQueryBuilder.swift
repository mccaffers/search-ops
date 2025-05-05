// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI


struct SearchQueryBuilder: View {
  
  @Binding var presentedSheet: SearchSheet?
  @Binding var validSearchResults : Bool
  @Binding var showingGrid : Bool
  @Binding var makeSearchRequest: Bool
  
  @Binding var loading: Bool
  
  var selectedIndex : String
  
  @EnvironmentObject var selectedHost: HostDetailsWrap
  
  @State var rotationDegrees = 0.0
  var buttonSize = CGFloat(26)
  
  func buttonDisabled() -> Bool {
    if selectedHost.item == nil {
      return true
    }
    
    return false
  }
  
  @State var hostButtonOffset = CGFloat(-200)
  @State var hostButtonScale = CGSize(width: 1.5, height: 1.5)
  
  @State var searchButtonOffset = CGFloat(-300)
  @State var searchButtonScale = CGSize(width: 1.5, height: 1.5)
  
  // There is a range of logic here to
  // ensure that the sheet buttons work
  // There is a bug when you press the button too fast
  // it does nothing
  
#if os(iOS)
  var textSize = UIDevice().hasNotch ? CGFloat(14) : CGFloat(13)
#else
  var textSize = CGFloat(14)
#endif
  
  @State private var scrollTarget: Int? = nil
  @State private var scrollViewProxy: ScrollViewProxy? = nil
  
  var stopTimer : () -> ()

  
  func abbreviateTimeUnit(_ unit: TimeUnit) -> String {
    switch unit {
    case .milliseconds:
      return "ms"
    case .seconds:
      return "s"
    case .minutes:
      return "m"
    case .hours:
      return "h"
    }
  }
  
  //  @Binding var postRequestUpdate: UUID
  var schedule: TimerInterval?
  
  @AppStorage("lastSeenVersionNotes") private var lastSeenVersionNotes: String = ""
  
  
  var body: some View {
    
    //    ScrollViewReader { proxy in
    //      ScrollView(.horizontal) {
    VStack (spacing:5) {
      HStack(spacing:5) {
        
        Button {
          presentedSheet = .recent
        } label: {
          HStack(spacing:4) {
            Image(systemName: "calendar")
            Text("Recent")
          }
          .frame(height: 50)
          .frame(maxWidth: .infinity)
          .foregroundColor(Color("ButtonText"))
          .background(Color("Button"))
          .cornerRadius(5)
        }
        
        
        
        Button {
          presentedSheet = .main
        } label: {
          HStack(spacing:4) {
            Image(systemName: "server.rack")
            Text("Hosts")
          }
          
          .frame(height: 50)
          .frame(maxWidth: .infinity)
          .foregroundColor(Color("ButtonText"))
          .background(Color("Button"))
          .cornerRadius(5)
        }
        
        
        
        Button {
          presentedSheet = .query
        } label: {
          HStack(spacing:4) {
            Image(systemName: "ellipsis.curlybraces")
            Text("Query")
          }
          .frame(height: 50)
          .frame(maxWidth: .infinity)
          .foregroundColor(Color("ButtonText"))
          .background(Color("Button"))
          .cornerRadius(5)
        }
        
        
        
        
        
        
      }
      
      HStack (spacing: 5) {
        
        Button  {
          
          if selectedHost.item != nil {
            presentedSheet = .fields
          }
          
        } label: {
          HStack(spacing:4) {
            Image(systemName: "list.dash")
            Text("Fields")
          }
          .frame(height: 50)
          .frame(maxWidth: .infinity)
          .foregroundColor(Color("ButtonText").opacity(buttonDisabled() ? 0.4 : 1))
          .background(Color("Button"))
          .cornerRadius(5)
          
        }
        
        
        Button  {
          showingGrid.toggle()
        } label: {
          
          VStack (spacing:4) {
            HStack {
              Image(systemName: !showingGrid ? "square.grid.3x3.fill" : "line.3.horizontal")
              
              
              Text(!showingGrid ? "Grid" : "List")
            }
            
          }
          .frame(height: 50)
          .frame(maxWidth: .infinity)
          .foregroundColor(Color("ButtonText").opacity(buttonDisabled() ? 0.4 : 1))
          .background(Color("Button"))
          .cornerRadius(5)
          
        }
        .disabled(buttonDisabled())

        Button  {
          if let schedule = schedule {
            Task {
              stopTimer()
            }
          } else {
            presentedSheet = .timer
          }
          
        } label: {
          
          VStack (spacing:4) {
            
            if let schedule = schedule {
              HStack(spacing:0) {
                Text(schedule.value.string)
                Text(abbreviateTimeUnit(schedule.unit))
              }
              
            } else {
              HStack(spacing:4) {
                Image(systemName: "clock.arrow.2.circlepath")
                Text("Timer")
              }
            }
          }
          .frame(height: 50)
          .frame(maxWidth: .infinity)
          .foregroundColor(Color("ButtonText").opacity(buttonDisabled() ? 0.4 : 1))
          .background(schedule == nil ? Color("Button") : Color("WarnTextHighlighted"))
          .cornerRadius(5)
        }
        .disabled(buttonDisabled())
        
        Button  {
          makeSearchRequest=true
          withAnimation {
            scrollViewProxy?.scrollTo("lastItem", anchor: .trailing)
          }
        } label: {
          if loading {
            VStack (spacing:4) {
              Image(systemName: "arrow.triangle.2.circlepath")
                .rotationEffect(Angle(degrees: self.rotationDegrees))
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .foregroundColor(Color("ButtonText").opacity(buttonDisabled() ? 0.4 : 1))
            .background(buttonDisabled() ? Color("Button") : Color("PositiveButton"))
            .cornerRadius(5)
            .onAppear {
              rotationDegrees=0
              
              let baseAnimation = Animation.linear(duration: 0.8)
              let repeated = baseAnimation.repeatForever(autoreverses: false)
              
              withAnimation(repeated) {
                rotationDegrees = 360
              }
            }

          } else {
            VStack (spacing:4) {
              HStack (spacing:3){
                Image(systemName: "magnifyingglass")
                Text("Search")
              }
              .frame(height: 40)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .foregroundColor(Color("ButtonText").opacity(buttonDisabled() ? 0.4 : 1))
            .background(buttonDisabled() ? Color("Button") : Color("PositiveButton"))
            .cornerRadius(5)
            
          }
        }.disabled(buttonDisabled())
      }
    }
  }
}
