// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosHostAddNameEnvViews: View {
  
  @State var hostname : String = ""
  @State var environment : String = ""
  
  @Binding var host : HostDetails
  var item: HostDetails? = nil
  var offset: CGFloat
  
  @FocusState var focusedField: String?
  @State var selectedNameField = false
  @State var selectedEnvironmentField = false
  @Binding var isHostValid : Bool
  
  var body: some View {
    VStack(spacing:10) {
      VStack (spacing:5) {
        Text("Name (eg. My Host)")
          .font(.system(size:12))
          .foregroundStyle(Color("TextSecondary"))
          .frame(maxWidth: .infinity, alignment: .leading)
        
        TextField("Name", text: $hostname)
          .textFieldStyle(PlainTextFieldStyle())
          .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
          .frame(height: 36)
          .background(Color("Button"))
          .clipShape(.rect(cornerRadius: 5))
          .overlay(
            RoundedRectangle(cornerRadius: 5)
              .stroke(Color("BackgroundAlt"), lineWidth: 1)
          )
          .onChange(of: hostname) { newValue in
            host.name = newValue
            isHostValid = host.isValid()
          }
          .focused($focusedField, equals: "name")
          .overlay(
            RoundedRectangle(cornerRadius: 5)
              .stroke(selectedNameField ? Color("LabelBackgroundBorder") : Color("BackgroundAlt"), lineWidth: 1)
          )
         
      }.padding(.top, 2)
      
      VStack (spacing:5) {
        Text("Environment (eg. Development)")
          .font(.system(size:12))
          .foregroundStyle(Color("TextSecondary"))
          .frame(maxWidth: .infinity, alignment: .leading)
        
        TextField("Environment", text: $environment)
          .textFieldStyle(PlainTextFieldStyle())
          .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
          .frame(height: 36)
          .background(Color("Button"))
          .clipShape(.rect(cornerRadius: 5))
          .overlay(
            RoundedRectangle(cornerRadius: 5)
              .stroke(Color("BackgroundAlt"), lineWidth: 1)
          )
          .onChange(of: environment) { newValue in
            host.env = newValue
          }
          .focused($focusedField, equals: "env")
          .overlay(
            RoundedRectangle(cornerRadius: 5)
              .stroke(selectedEnvironmentField ? Color("LabelBackgroundBorder") : Color("BackgroundAlt"), lineWidth: 1)
          )
         
        
      }
    }
    .onChange(of: focusedField, perform: { newValue in
      // selected the textfield view, needs a negative check on selected
      // or swiftui loops forever
      if newValue == "name" && !selectedNameField {
        selectedNameField = true
      } else if selectedNameField && newValue != "name" {
        selectedNameField = false
      }
      
      // selected the textfield view, needs a negative check on selected
      // or swiftui loops forever
      if newValue == "env" && !selectedEnvironmentField {
        selectedEnvironmentField = true
      } else if selectedEnvironmentField && newValue != "env" {
        selectedEnvironmentField = false
      }
    })
    .onAppear {
     

      if item != nil {
        if let name = item?.name {
          hostname = name
          host.name = name
        }
        if let env = item?.env {
          environment = env
          host.env = env
        }
      } else {
        hostname = host.name
        environment = host.env
      }
    
      // if there is animation offset, the view is just appearing,
      // lets delay the connection details appearing for 0.5 seconds
      let delay = offset != 0 ? 0.4 : 0
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        selectedNameField = true
        focusedField = "name"
      }
    }
  }
}
