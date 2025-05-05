// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosHostAddConnectionDetailsView: View {
  
  @Binding var host : HostDetails
  var item: HostDetails? = nil
  var offset: CGFloat
  
  @State var cloudID : String = ""
  @State var hostURL : String = ""
  @State var port : String = ""
  @State var selfSignedCertificates = false
  @State private var connectionType : ConnectionType = ConnectionType.CloudID

  @FocusState var focusedField: String?
  @State var selectedHostnameField = false
  @State var selectedPortField = false
  @State var selectedCloudIDField = false
  
  @Binding var isHostValid : Bool
  
    var body: some View {
      VStack(spacing:10) {
        VStack (spacing:5) {
          
          Text("Connection Type")
            .font(.system(size:12))
            .foregroundStyle(Color("TextSecondary"))
            .frame(maxWidth: .infinity, alignment: .leading)
          
          HStack {
            Button {
              connectionType = .CloudID
            } label: {
              Text("Cloud ID")
                .padding(10)
                .background(connectionType == .CloudID ? Color("ButtonHighlighted") : Color("Button"))
                .clipShape(.rect(cornerRadius: 5))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            
            Button {
              connectionType = .URL
            } label: {
              Text("Host & Port")
                .padding(10)
                .background(connectionType == .URL ? Color("ButtonHighlighted") : Color("Button"))
                .clipShape(.rect(cornerRadius: 5))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
          }
          .onChange(of: connectionType) { newValue in
            host.connectionType = newValue
            if newValue == .URL {
              if host.host == nil {
                host.host = HostURL()
              }
            }
          }
        }.onAppear {
          if item != nil {
            if let currentConnectionType = item?.connectionType {
              let delay = offset != 0 ? 0.4 : 0
              DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation {
                  connectionType = currentConnectionType
                  host.connectionType = currentConnectionType
                }
              }
            }
          } else {
            self.connectionType = host.connectionType
          }
        }
        
        if connectionType == .CloudID {
          VStack (spacing:5) {
            Text("Cloud ID (from elastic.co)")
              .font(.system(size:12))
              .foregroundStyle(Color("TextSecondary"))
              .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Cloud ID", text: $cloudID)
              .textFieldStyle(PlainTextFieldStyle())
              .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
              .frame(height: 36)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .overlay(
                RoundedRectangle(cornerRadius: 5)
                  .stroke(Color("BackgroundAlt"), lineWidth: 1)
              )
              .onChange(of: cloudID) { newValue in
                host.cloudid = newValue
                isHostValid = host.isValid()
              }
              .onAppear {
                if item != nil {
                  if let currentCloudID = item?.cloudid {
                    self.cloudID = currentCloudID
                    host.cloudid = currentCloudID
                    isHostValid = host.isValid()
                  }
                } else {
                  self.cloudID = host.cloudid
                }
              }
              .focused($focusedField, equals: "cloudid")
              .onChange(of: focusedField, perform: { newValue in
                // selected the textfield view, needs a negative check on selected
                // or swiftui loops forever
                if newValue == "cloudid" && !selectedCloudIDField {
                  selectedCloudIDField = true
                } else if selectedCloudIDField && newValue != "cloudid" {
                  selectedCloudIDField = false
                }
              })
              .overlay(
                RoundedRectangle(cornerRadius: 5)
                  .stroke(selectedCloudIDField ? Color("LabelBackgroundBorder") : Color("BackgroundAlt"), lineWidth: 1)
              )
            
          }
        } else if connectionType == .URL {
          VStack (spacing:5) {
            Text("Host URL and Port")
              .font(.system(size:12))
              .foregroundStyle(Color("TextSecondary"))
              .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("URL", text: $hostURL)
              .textFieldStyle(PlainTextFieldStyle())
              .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
              .frame(height: 36)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .overlay(
                RoundedRectangle(cornerRadius: 5)
                  .stroke(Color("BackgroundAlt"), lineWidth: 1)
              )
              .onChange(of: hostURL) { newValue in
                if host.host == nil {
                  host.host = HostURL()
                }
                host.host?.url = newValue
                isHostValid = host.isValid()
              }
              .onAppear {
                if let item = item,
                   let currentHost = item.host {
                  hostURL = currentHost.url
                  
                  if host.host == nil {
                    host.host = HostURL()
                  }
                  host.host?.url = currentHost.url
                  
                  isHostValid = host.isValid()
                } else if let url =  host.host?.url {
                  self.hostURL = url
                }
              }
              .focused($focusedField, equals: "hostname")
              .overlay(
                RoundedRectangle(cornerRadius: 5)
                  .stroke(selectedHostnameField ? Color("LabelBackgroundBorder") : Color("BackgroundAlt"), lineWidth: 1)
              )
            
            TextField("Port (defaults 443)", text: $port)
              .textFieldStyle(PlainTextFieldStyle())
              .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
              .frame(height: 36)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .overlay(
                RoundedRectangle(cornerRadius: 5)
                  .stroke(Color("BackgroundAlt"), lineWidth: 1)
              )
              .onChange(of: port) { newValue in
                host.host?.port = newValue
              }
              .onAppear {
                if let item = item,
                   let port = item.host?.port {
                  if host.host == nil {
                    host.host = HostURL()
                  }
                  self.host.host?.port = port
                  
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                      self.port = port
                    }
                  }
                } else if let port =  host.host?.port {
                  self.port = port
                }
              }
              .focused($focusedField, equals: "port")
              .overlay(
                RoundedRectangle(cornerRadius: 5)
                  .stroke(selectedPortField ? Color("LabelBackgroundBorder") : Color("BackgroundAlt"), lineWidth: 1)
              )
            
            Button {
              
              selfSignedCertificates.toggle()
              host.host?.selfSignedCertificate = selfSignedCertificates
            } label: {
              HStack {
                Spacer()
                Text("Allow self signed certificates")
                Image(systemName: selfSignedCertificates ? "checkmark.circle.fill" : "circle")
                  .padding(10)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
              }
            }.buttonStyle(PlainButtonStyle())
              .frame(maxWidth: .infinity)
              .onAppear {
                if let item = item,
                   let selfSigned = item.host?.selfSignedCertificate {
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                      self.selfSignedCertificates = selfSigned
                      if host.host == nil {
                        host.host = HostURL()
                      }
                      self.host.host?.selfSignedCertificate = selfSigned
                    }
                  }
                } else if let selfSignedCertificates =  host.host?.selfSignedCertificate {
                  self.selfSignedCertificates = selfSignedCertificates
                }
              }
          }
          .onChange(of: focusedField, perform: { newValue in
            // selected the textfield view, needs a negative check on selected
            // or swiftui loops forever
            if newValue == "port" && !selectedPortField {
              selectedPortField = true
            } else if selectedPortField && newValue != "port" {
              selectedPortField = false
            }
            
            // selected the textfield view, needs a negative check on selected
            // or swiftui loops forever
            if newValue == "hostname" && !selectedHostnameField {
              selectedHostnameField = true
            } else if selectedHostnameField && newValue != "hostname" {
              selectedHostnameField = false
            }            
          })
        }
      }
    }
}
