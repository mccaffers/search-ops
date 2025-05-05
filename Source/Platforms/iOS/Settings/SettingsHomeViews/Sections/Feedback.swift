// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct Feedback: View {
  
  @State var showingAnalyticsMessage = false
  
  func emailText() -> AttributedString {
    var message1: AttributedString {
      var result = AttributedString("You can email me feedback at ")
      result.font = .system(size: 15, weight:.regular)
      result.foregroundColor = Color("TextSecondary")
      
      return result
    }
    
    var message2: AttributedString {
      var result = AttributedString("ryan@mccaffers.com")
      result.font = .system(size: 15, weight:.regular)
      result.foregroundColor = Color("ButtonLight")
      
      return result
    }
    
    let twoatt = message1 + message2
    
    return twoatt
    
  }
  
  var body: some View {
    VStack(spacing:5) {
      
      VStack (spacing:10){
        
        Button {
          showingAnalyticsMessage = true
        } label: {
          HStack (spacing:5) {     
            Text("No Analytics or Tracking")
              .foregroundColor(Color("TextSecondary"))
            Image(systemName: "info.square.fill")
              .font(.system(size:20))
          }
          .foregroundColor(Color("ButtonLight"))
        }.frame(maxWidth: .infinity, alignment: .leading)

        
        Text("Please contact me if you have any issues or feedback.")
          .font(.system(size:15))
          .frame(maxWidth: .infinity, alignment: .leading)
          .multilineTextAlignment(.leading)
        
        Link(destination: URL(string: "mailto:ryan@mccaffers.com")!) {
          
          Text(emailText()) //.map { Text("\($0) ") }.reduce(Text(""), +)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
        }.frame(maxWidth: .infinity, alignment: .leading)
        
        
      }.frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(Color("TextSecondary"))
        .font(.system(size:14))
        .padding(15)
        .background(Color("BackgroundAlt"))
        .cornerRadius(5)
    }
    .navigationDestination(isPresented:$showingAnalyticsMessage, destination: {
      SettingsAnalyticsMessageView()
    })
  }
}

#Preview {
    Feedback()
}
#endif
