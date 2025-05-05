// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct ElasticHelpView: View {
  var body: some View {
    ScrollView {
      VStack(
        alignment: .leading,
        spacing: 20
      ) {
        
        Text("Descriptions")
          .font(.system(size: 15))
          .foregroundStyle(Color("TextSecondary"))
          .padding(.top, 20)
          .frame(maxWidth: .infinity, alignment: .leading)
        
        Text("The two local variables, `Name` and `Environment` are to help you identify your infrastructure throughout the Search Ops app. They can be any value.")
          .font(.system(size: 15))
        
        HostAddDivider()
        
        Text("Connection Details")
          .font(.system(size: 15))
          .foregroundStyle(Color("TextSecondary"))
        
        Text("You can connect with either a `Cloud ID` (provided by Elastic.co) or using a `Host URL` and a `Port`")
          .font(.system(size: 15))

        HostAddDivider()

        Text("Authentication")
          .font(.system(size: 15))
          .foregroundStyle(Color("TextSecondary"))
        
        Text("Four options for authentication, `Username` & `Password`, `Auth Token`, `API token` and `No Auth`")
   
        HostAddDivider()

        Text("Custom Headers")
          .font(.system(size: 15))
          .foregroundStyle(Color("TextSecondary"))

        Text("Add custom headers to be sent alongside any requests made. This can help you identify SearchOps activity on your host")
        
        Spacer()
      }
      .padding(.horizontal, 20)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  
    .background(Color("Background"))
    .navigationBarTitle("Guidance")
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)

  }
}

struct ElasticHelpView_Previews: PreviewProvider {
  static var previews: some View {
    ElasticHelpView()
  }
}
#endif
