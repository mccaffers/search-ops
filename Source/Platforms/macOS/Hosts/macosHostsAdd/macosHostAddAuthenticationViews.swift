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
  var connectionType: ConnectionType
  
  @State private var username: String = ""
  @State private var password: String = ""
  @State private var authToken: String = ""
  @State private var apiToken: String = ""
  @State private var apiKey: String = ""
  @State private var awsAccessKeyId: String = ""
  @State private var awsSecretAccessKey: String = ""
  @State private var awsSessionToken: String = ""
  @State private var awsRegion: String = ""
  @State private var awsService: AWSService = .es
  
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
        ForEach(AuthenticationTypes.available(for: connectionType), id: \.self) { type in
          Button {
            authType = type
          } label: {
            Text(type.shortName)
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
    .onChange(of: connectionType) { newValue in
      if !authType.isAvailable(for: newValue) {
        authType = .None
      }
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
      case .AWSSigV4:
        awsSigV4Fields
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
  
  private func authTextField(_ title: String, text: Binding<String>, secure: Bool = false) -> some View {
    Group {
      if secure {
        SecureField(title, text: text)
      } else {
        TextField(title, text: text)
      }
    }
    .textFieldStyle(PlainTextFieldStyle())
    .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
    .frame(height: 36)
    .background(Color("Button"))
    .clipShape(.rect(cornerRadius: 5))
    .overlay(
      RoundedRectangle(cornerRadius: 5)
        .stroke(Color("BackgroundAlt"), lineWidth: 1)
      )
  }
  
  private var awsSigV4Fields: some View {
    VStack(alignment: .leading, spacing: 5) {
      authTextField("Access Key ID", text: $awsAccessKeyId)
        .onChange(of: awsAccessKeyId) { newValue in
          host.awsAccessKeyId = newValue
        }
      
      authTextField("Secret Access Key", text: $awsSecretAccessKey, secure: true)
        .onChange(of: awsSecretAccessKey) { newValue in
          host.awsSecretAccessKey = newValue
        }
      
      authTextField("Session Token (optional)", text: $awsSessionToken, secure: true)
        .onChange(of: awsSessionToken) { newValue in
          host.awsSessionToken = newValue
        }
      
      HStack(spacing: 5) {
        authTextField("Region (eg. eu-west-2)", text: $awsRegion)
          .onChange(of: awsRegion) { newValue in
            host.awsRegion = newValue
          }
        
        HStack(spacing: 5) {
          ForEach(AWSService.allCases, id: \.self) { service in
            Button {
              awsService = service
            } label: {
              Text(service.rawValue)
                .padding(10)
                .background(awsService == service ? Color("ButtonHighlighted") : Color("Button"))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .contentShape(Rectangle())
                .help(service.displayName)
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
        .onChange(of: awsService) { newValue in
          host.awsService = newValue
        }
      }
      
      Text("Use an IAM user's access keys, or temporary credentials with a session token. Custom headers named Authorization, Host, Content-Type or X-Amz-* aren't sent.")
        .font(.system(size: 11))
        .foregroundStyle(Color("TextSecondary"))
        .fixedSize(horizontal: false, vertical: true)
    }
    .onAppear {
      let source = item ?? host
      awsAccessKeyId = source.awsAccessKeyId
      awsSecretAccessKey = source.awsSecretAccessKey
      awsSessionToken = source.awsSessionToken
      awsRegion = source.awsRegion
      awsService = source.awsService
      
      // Pre-fill region and service from the endpoint, the user can override them
      if awsRegion.isEmpty, let detected = AWSEndpoint.detect(host.host?.url ?? "") {
        awsRegion = detected.region
        awsService = detected.service
      }
      
      host.awsAccessKeyId = awsAccessKeyId
      host.awsSecretAccessKey = awsSecretAccessKey
      host.awsSessionToken = awsSessionToken
      host.awsRegion = awsRegion
      host.awsService = awsService
    }
  }

}
