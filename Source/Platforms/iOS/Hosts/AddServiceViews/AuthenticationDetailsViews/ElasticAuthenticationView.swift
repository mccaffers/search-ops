// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import RealmSwift

struct ElasticAuthenticationView: View {
  
  @Binding var item: HostDetails
  @FocusState var focusedField: String?
  @Binding var currentField: String
  
  @State private var selection : AuthenticationTypes = AuthenticationTypes.None
  
  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 5
    )  {
      
      AddHostHeaderLabel(title:"Authentication")
      
      VStack(spacing:10){
        
        HStack {
          
          Menu {
            ForEach(AuthenticationTypes.allCases, id: \.self) { index in
              Button {
                selection = index
              } label: {
                Text("\(index.rawValue)")
              }
            }
          }
          label: {
            HStack {
              Text(selection.rawValue)
                .font(.system(size: 15))
              Text(Image(systemName: "chevron.down"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color("Button"))
            .cornerRadius(5)
            .foregroundColor(.white)
            
          }
          .onChange(of: selection) { newValue in
            
            HostsDataManager.updateAuthentication(item: item, selection: selection)
          }
        }
        
        if selection != .None {
          VStack(spacing:10){
            if selection == AuthenticationTypes.UsernamePassword {
              AddConnectionLabel(identifer: "Username", 
                                 value: $item.username,
                                 currentField: $currentField,
                                 focusedField: _focusedField,
                                 placeholder: "Username",
                                 schemaUpdate: .constant(.HTTPS))
              
              AddConnectionLabel(identifer: "Password", 
                                 value: $item.password,
                                 currentField: $currentField,
                                 focusedField: _focusedField,
                                 placeholder: "Password",
                                 schemaUpdate: .constant(.HTTPS))
              
            }
            
            if selection == AuthenticationTypes.AuthToken {
              AddConnectionLabel(identifer: "Auth Token", 
                                 value: $item.authToken,
                                 currentField: $currentField,
                                 focusedField: _focusedField,
                                 placeholder: "Authentication Token",
                                 schemaUpdate: .constant(.HTTPS))
            }
            
            if selection == AuthenticationTypes.APIToken {
              AddConnectionLabel(identifer: "API Token", 
                                 value: $item.apiToken,
                                 currentField: $currentField,
                                 focusedField: _focusedField,
                                 placeholder: "API Token",
                                 schemaUpdate: .constant(.HTTPS))
            }
            
            if selection == AuthenticationTypes.APIKey {
              AddConnectionLabel(identifer: "API Key", 
                                 value: $item.apiKey,
                                 currentField: $currentField,
                                 focusedField: _focusedField,
                                 placeholder: "API Key",
                                 schemaUpdate: .constant(.HTTPS))
            }
          }
        }
      }
      .padding(.horizontal, 20)
      
    }
    .onAppear {
      self.selection = item.authenticationType
    }
  }
}
