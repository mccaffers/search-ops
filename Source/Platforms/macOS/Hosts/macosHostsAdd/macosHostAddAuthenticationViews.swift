// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosHostAddAuthenticationViews: View {
  @Binding var host: HostDetails
  var item: HostDetails? = nil
  var offset: CGFloat
  
  @State private var username: String = ""
  @State private var password: String = ""
  @State private var authToken: String = ""
  @State private var apiToken: String = ""
  @State private var apiKey: String = ""
  
  @State private var authType: AuthenticationTypes = .None
  
  var body: some View {
    VStack(spacing: 10) {
      authTypeSelector
        .padding(.bottom, authType == .None ? 4 : 0)
      if authType != .None {
        authenticationFields
      }
    }
  }
  
  private var authTypeSelector: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text("Authentication Type")
        .font(.system(size: 12))
        .foregroundStyle(Color("TextSecondary"))
      
      HStack(spacing: 5) {
        ForEach(AuthenticationTypes.allCases, id: \.self) { type in
          Button {
            authType = type
          } label: {
            Text(type.rawValue)
              .padding(10)
              .background(authType == type ? Color("ButtonHighlighted") : Color("Button"))
              .clipShape(RoundedRectangle(cornerRadius: 5))
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .onAppear {
        if let item = item {
          // if there is animation offset, the view is just appearing,
          // lets delay the authentication appearing for 0.3 seconds
          let delay = offset != 0 ? 0.4 : 0
          DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation {
              authType = item.authenticationType
              host.authenticationType = item.authenticationType
            }
          }
        } else {
          self.authType = host.authenticationType
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onChange(of: authType) { newValue in
      host.authenticationType = newValue
    }
  }
  
  private var authenticationFields: some View {
    VStack(alignment: .leading, spacing: 5) {
      
      if authType != .None {
        Text("Authentication")
          .font(.system(size: 12))
          .foregroundStyle(Color("TextSecondary"))
      }
      
      switch authType {
      case .None:
        EmptyView() // not shown tho
      case .UsernamePassword:
        usernamePasswordFields
      case .AuthToken:
        authTokenField
      case .APIToken:
        apiTokenField
      case .APIKey:
        apiKeyField
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var usernamePasswordFields: some View {
    VStack(spacing: 5) {
      TextField("Username", text: $username)
        .textFieldStyle(PlainTextFieldStyle())
        .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
        .frame(height: 36)
        .background(Color("Button"))
        .clipShape(.rect(cornerRadius: 5))
        .overlay(
          RoundedRectangle(cornerRadius: 5)
            .stroke(Color("BackgroundAlt"), lineWidth: 1)
          )
        .onChange(of: username) { newValue in
          host.username = newValue
        }
        .onAppear {
          if let item = item {
            username = item.username
            host.username = item.username
          } else {
            self.username = host.username
          }
        }
      
      SecureField("Password", text: $password)
        .textFieldStyle(PlainTextFieldStyle())
        .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
        .frame(height: 36)
        .background(Color("Button"))
        .clipShape(.rect(cornerRadius: 5))
        .overlay(
          RoundedRectangle(cornerRadius: 5)
            .stroke(Color("BackgroundAlt"), lineWidth: 1)
          )
        .onChange(of: password) { newValue in
          host.password = newValue
        }
        .onAppear {
          if let item = item {
            password = item.password
            host.password = item.password
          } else {
            self.password = host.password
          }
        }
    }
  }
  
  private var authTokenField: some View {
    TextField("Auth Token", text: $authToken)
      .textFieldStyle(PlainTextFieldStyle())
      .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
      .frame(height: 36)
      .background(Color("Button"))
      .clipShape(.rect(cornerRadius: 5))
      .overlay(
        RoundedRectangle(cornerRadius: 5)
          .stroke(Color("BackgroundAlt"), lineWidth: 1)
        )
      .onChange(of: authToken) { newValue in
        host.authToken = newValue
      }
      .onAppear {
        if let item = item {
          authToken = item.authToken
          host.authToken = item.authToken
        } else {
          self.authToken = host.authToken
        }
      }
  }
  
  private var apiTokenField: some View {
    TextField("API Token", text: $apiToken)
      .textFieldStyle(PlainTextFieldStyle())
      .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
      .frame(height: 36)
      .background(Color("Button"))
      .clipShape(.rect(cornerRadius: 5))
      .overlay(
        RoundedRectangle(cornerRadius: 5)
          .stroke(Color("BackgroundAlt"), lineWidth: 1)
        )
      .onChange(of: apiToken) { newValue in
        host.apiToken = newValue
      }
      .onAppear {
        if let item = item {
          apiToken = item.apiToken
          host.apiToken = item.apiToken
        } else {
          self.apiToken = host.apiToken
        }
      }
  }
  
  private var apiKeyField: some View {
    TextField("API Key", text: $apiKey)
      .textFieldStyle(PlainTextFieldStyle())
      .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
      .frame(height: 36)
      .background(Color("Button"))
      .clipShape(.rect(cornerRadius: 5))
      .overlay(
        RoundedRectangle(cornerRadius: 5)
          .stroke(Color("BackgroundAlt"), lineWidth: 1)
        )
      .onChange(of: apiKey) { newValue in
        host.apiKey = newValue
      }
      .onAppear {
        if let item = item {
          apiKey = item.apiKey
          host.apiKey = item.apiKey
        } else {
          self.apiKey = host.apiKey
        }
      }
  }
}
