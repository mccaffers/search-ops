// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import RealmSwift

struct ElasticConnectionDetails: View {
  
  @Binding var item: HostDetails
  @FocusState var focusedField: String?
  @Binding var currentField: String
  
  @State private var selection : ConnectionType = ConnectionType.CloudID
  
  var body: some View {
    VStack (spacing:15) {
      HStack {
        Menu {
          ForEach(ConnectionType.allCases, id: \.self) { index in
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
        
        // Check if the newValue has changed from the default
        if newValue != item.connectionType {
          HostsDataManager.setConncetionType(item: item, connection: selection)
          focusedField = nil
        }
        
      }
      }
      .padding(.horizontal, 20)
      
      Group {
        if selection == ConnectionType.CloudID {
          ElasticCloudIDView(item: $item, currentField: $currentField, focusedField: _focusedField)
        } else {
          if let schema = item.host?.scheme {
            AddHostConnectionView(item: $item, currentField: $currentField, focusedField: _focusedField, schemaUpdate: schema)
          } else {
            AddHostConnectionView(item: $item, currentField: $currentField, focusedField: _focusedField)
          }
        }
      }.padding(.horizontal, 20)
      
    }
    
    .onAppear {
      self.selection = item.connectionType
    }
  }
}
