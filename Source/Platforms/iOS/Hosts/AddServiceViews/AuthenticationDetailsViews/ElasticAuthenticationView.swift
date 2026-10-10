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
  var connectionType: ConnectionType
  
  @State private var selection : AuthenticationTypes = AuthenticationTypes.None
  @State private var awsService : AWSService = .es
  
  var body: some View {
    VStack(
      alignment: .leading,
      spacing: 5
    )  {
      
      AddHostHeaderLabel(title:"Authentication")
      
      VStack(spacing:10){
        
        HStack {
          
          Menu {
            ForEach(AuthenticationTypes.available(for: connectionType), id: \.self) { index in
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
            
            if selection == AuthenticationTypes.AWSSigV4 {
              awsSigV4Fields
            }
          }
        }
      }
      .padding(.horizontal, 20)
      
    }
    .onAppear {
      self.selection = item.authenticationType
    }
    .onChange(of: connectionType) { newValue in
      if !selection.isAvailable(for: newValue) {
        selection = .None
      }
    }
  }
  
  private var awsSigV4Fields: some View {
    VStack(spacing:10) {
      AddConnectionLabel(identifer: "Access Key ID",
                         value: $item.awsAccessKeyId,
                         currentField: $currentField,
                         focusedField: _focusedField,
                         placeholder: "Access Key ID",
                         schemaUpdate: .constant(.HTTPS))
      
      AddConnectionLabel(identifer: "Secret Access Key",
                         value: $item.awsSecretAccessKey,
                         currentField: $currentField,
                         focusedField: _focusedField,
                         placeholder: "Secret Access Key",
                         schemaUpdate: .constant(.HTTPS),
                         secure: true)
      
      AddConnectionLabel(identifer: "Session Token",
                         value: $item.awsSessionToken,
                         currentField: $currentField,
                         focusedField: _focusedField,
                         placeholder: "Session Token (optional)",
                         schemaUpdate: .constant(.HTTPS),
                         secure: true)
      
      AddConnectionLabel(identifer: "Region",
                         value: $item.awsRegion,
                         currentField: $currentField,
                         focusedField: _focusedField,
                         placeholder: "Region (eg. eu-west-2)",
                         schemaUpdate: .constant(.HTTPS))
      
      Menu {
        ForEach(AWSService.allCases, id: \.self) { service in
          Button {
            awsService = service
          } label: {
            Text(service.displayName)
          }
        }
      }
      label: {
        HStack {
          Text(awsService.displayName)
            .font(.system(size: 15))
          Text(Image(systemName: "chevron.down"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color("Button"))
        .cornerRadius(5)
        .foregroundColor(.white)
      }
      .onChange(of: awsService) { newValue in
        item.awsService = newValue
      }
      
      Text("Use an IAM user's access keys, or temporary credentials with a session token. Custom headers named Authorization, Host, Content-Type or X-Amz-* aren't sent.")
        .font(.system(size: 13))
        .foregroundColor(Color("TextSecondary"))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .onAppear {
      // Pre-fill region and service from the endpoint, the user can override them
      if item.awsRegion.isEmpty, let detected = AWSEndpoint.detect(item.host?.url ?? "") {
        item.awsRegion = detected.region
        item.awsService = detected.service
      }
      awsService = item.awsService
    }
  }

}
