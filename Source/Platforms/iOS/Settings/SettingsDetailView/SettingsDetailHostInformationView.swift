// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SettingsDetailHostInformationView: View {
  
  var hostname = ""
  var environment = ""
  var datefield = ""
  var index = ""
  
  var body: some View {
    VStack {
      VStack {
        HStack {
          Text("Host Information")
            .padding(.vertical, 10)
            .foregroundColor(Color("TextColor"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 15)
      }
      .padding(.vertical, 10)
      .background(Color("BackgroundAlt"))
      
      VStack(spacing:10) {
        HStack(spacing:10) {
          Text("Host")
            .frame(width: 120, alignment: .trailing)
          Text(hostname)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        if !index.isEmpty {
          HStack(spacing:10) {
            Text("Index")
              .frame(width: 120, alignment: .trailing)
            Text(index)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        
        HStack(spacing:10) {
          Text("Environment")
            .frame(width: 120, alignment: .trailing)
          Text(environment)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        
        if !datefield.isEmpty {
          HStack(spacing:10) {
            Text("Date Field")
              .frame(width: 120, alignment: .trailing)
            
            
            Text(datefield)
              .frame(maxWidth: .infinity, alignment: .leading)
            
            
            
          }
        }
      }
    }
    
  }
}
