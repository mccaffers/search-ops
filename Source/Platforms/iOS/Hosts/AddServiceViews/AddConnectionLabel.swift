// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct AddConnectionLabel: View {
  
  var identifer : String
  // Passed State
  @Binding var value: String
  @State var innerValue: String = ""
  @EnvironmentObject var navigationTitle: AddServiceNavigationTitle
  @EnvironmentObject var observeFieldChanges: ObserveFieldChanges
  
  @Binding var currentField: String
  
  @FocusState var focusedField: String?
  
  // Local state
  @State var showView = false
  
  // Local variables
  var name: String? = nil
  var placeholder: String
  @State private var selected: Bool = false
  var optionalTag = false
  
  @Binding var schemaUpdate : HostScheme
  
  // Hides the value, for secrets
  var secure = false
  
  // Receives the port from a tidied "Host URL", which this label doesn't own
  var onPortParsed: ((String) -> Void)? = nil
  
  // Moves the scheme, port and any path out of a pasted address
  private func tidyHostURL() {
    let address = HostAddress.parse(value)
    if value != address.host {
      value = address.host
      innerValue = address.host
    }
    if let scheme = address.scheme {
      schemaUpdate = scheme
    }
    if let port = address.port {
      onPortParsed?(port)
    }
  }
  
  @ViewBuilder
  private var inputField: some View {
    if secure {
      SecureField("", text: $innerValue, prompt: Text(placeholder).foregroundColor(.gray))
    } else {
      TextField (
        "", // Placeholder
        text:$innerValue,
        prompt: Text(placeholder).foregroundColor(.gray)
      )
    }
  }
  
  @ViewBuilder
  var body: some View {
    VStack (spacing:0) {
      
      if let name = name {
        HStack {
          Text(name)
          Spacer()
          if optionalTag {
            Text("Optional")
              .foregroundColor(Color("TextSecondary"))
              .padding(.trailing, 30)
          }
        }
        .font(.system(size: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 10)
      }
      
      HStack (spacing:0) {
        
        inputField
        .focused($focusedField, equals: identifer)
#if os(iOS)
        .keyboardType(.alphabet)
        .textInputAutocapitalization(.never)
#endif
        .autocorrectionDisabled()
        .textFieldStyle(SelectedTextStyle(focused: $selected))
        .onTapGesture {
          // = name;
        }
        .onChange(of: focusedField, perform: { newValue in
          // selected the textfield view, needs a negative check on selected
          // or swiftui loops forever
          if newValue == identifer && !selected {
            selected = true
          } else if selected && newValue != identifer {
            selected = false
            
            if identifer == "Host URL" {
              tidyHostURL()
            }
          }
        })
        .onChange(of: innerValue, perform: { newValue in
          value=newValue
          observeFieldChanges.change = UUID().uuidString
          
          // A pasted URL, eg. from the AWS console, is tidied straight away
          if identifer == "Host URL" && newValue.contains("://") {
            tidyHostURL()
          }
        })
        .onAppear {
          innerValue=value
        }.background(Color("Background"))
        
        
        Spacer()
        
        // Textfield Expand button
        Button( action:{
          showView=true
        }){
          
          Image(systemName: "rectangle.expand.vertical")
            .foregroundColor(Color("TextIconColor"))
        }
        
      }
      
      
      
    }
    
    .onAppear{
      
      Task { @MainActor in
        
        //                self.focusedField = currentField
      }
      
    }
    .navigationDestination(isPresented: $showView) {
      LargeTextField(name:identifer, value:$value,
                     focusedField:_focusedField,
                     currentField: $currentField)
    }
  }
}

struct SelectedTextStyle: TextFieldStyle {
	
    @Binding var focused: Bool
		var padding : CGFloat = CGFloat(10)
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        
        configuration
            .padding(padding)
            .background(
							RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(focused ? Color("LabelBackgroundFocus") : Color("LabelBackgrounds"), lineWidth: 2)
									
            )

    }
}

struct SelectedTextStyleWithoutBinding: TextFieldStyle {
	
		var focused: Bool
		var padding : CGFloat = CGFloat(10)
		
		func _body(configuration: TextField<Self._Label>) -> some View {
				
				configuration
						.padding(padding)
						.background(
							RoundedRectangle(cornerRadius: 5, style: .continuous)
										.stroke(focused ? Color("LabelBackgroundFocus") : Color("LabelBackgrounds"), lineWidth: 2)
									
						).task {
							print(focused)
						}

		}
}





