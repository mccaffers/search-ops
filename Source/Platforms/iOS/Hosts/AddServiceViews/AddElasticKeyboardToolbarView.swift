// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct AddElasticKeyboardToolbarView: View {
  
  @State var item: HostDetails
  @FocusState var focusedField: String?
  
  var body: some View {
    HStack {
      Button {
        
        if focusedField?.string == "Environment" {
          focusedField = "Name"
        } else if item.connectionType == ConnectionType.CloudID {
          if focusedField?.string == "Cloud ID" {
            focusedField = "Environment"
          }
        } else if item.connectionType == ConnectionType.URL {
          if focusedField?.string == "Port" {
            focusedField = "Host URL"
          } else if focusedField?.string == "URL" {
            focusedField = "Environment"
          }
        }
        
      } label: {
        Image(systemName: "chevron.up")
      }
      
      Button {
        
        if focusedField?.string == "Name" {
          focusedField = "Environment"
        } else if focusedField?.string == "Environment" {
          if item.connectionType == ConnectionType.CloudID {
            focusedField = "Cloud ID"
          } else if item.connectionType == ConnectionType.URL {
            focusedField = "Host URL"
          }
        } else if focusedField?.string == "Host URL" {
          focusedField = "Port"
        } else if focusedField?.string == "Port" {
          if item.authenticationType == AuthenticationTypes.None {
#if os(iOS)
            dismissKeyboard()
#endif
          } else if item.authenticationType == AuthenticationTypes.UsernamePassword {
            focusedField = "Username"
          }
        } else if focusedField?.string == "Username" {
          focusedField = "Password"
        } else if focusedField?.string == "Cloud ID" {
          if item.customHeaders.count == 0 {
#if os(iOS)
            dismissKeyboard()
#endif
          } else {
            focusedField = 0.0.string
          }
        } else if focusedField?.string == Double(0).string {
          focusedField = 0.5.string
        } else if let focusedString = focusedField?.string, (Double(focusedString) ?? 0.0) >= 0.5 {
          let newValue = (Double(focusedString) ?? 0.0)+0.5
          focusedField = newValue.string
        }
        
      } label: {
        Image(systemName: "chevron.down")
      }
      
      Spacer()
      
      Button {
#if os(iOS)
        dismissKeyboard()
#endif
      } label: {
        Image(systemName: "keyboard.chevron.compact.down")
      }
    }
  }
}
