// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

struct macosHostsListView: View {
  
  @Binding var items : [HostDetails]
  @Binding var fullScreen : Bool
  @Binding var selection: macosSearchViewEnum
  @Binding var selectedHostToEdit : HostDetails?
  
    var body: some View {
      VStack {
        HStack(spacing:2) {
          
          Text("Host Management")
            .font(.system(size: 22, weight:.light))
          
         
          Spacer()
        }    
        .padding(.top, 10)
        .padding(.bottom, 0)
        .opacity(selection != .None ? 0.4 : 1)

        VStack(alignment:.leading, spacing:5){
          
          Button {
            selectedHostToEdit = nil
            selection = .HostManagement
          } label: {
            HStack(spacing:5) {
              Image(systemName: "plus.app.fill")
              Text("Add a new host")
            }
            .padding(10)
            .background(Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
            
          }
          .buttonStyle(PlainButtonStyle())
          .padding(.bottom, 5)
          .opacity(selection != .None ? 0.4 : 1)
          
          if items.count == 0 {
            RepeatedPlaceholderView()
            Spacer()
          } else {
            ScrollView {
              ForEach(items.indices, id: \.self) {  index in
                if !items[index].isInvalidated {
                  HStack {
                    macosHostManagementHomeButton(selectedHostToEdit: $selectedHostToEdit,
                                                  selection: $selection,
                                                  item: items[index])
                  }
                  .opacity(selection != .None ? 0.4 : 1)
                  
                }
              }
            }
          }
        
        }
        .frame(maxWidth: .infinity,alignment: .leading)
   
      }
      .padding(.horizontal,10)
      .background(Color("BackgroundFixedShadow"))
      .clipShape(.rect(cornerRadius: 5))
      .padding(.leading, 3)
      .padding(.trailing, 5)
      .padding(.bottom, 5)
      .padding(.top, fullScreen ? 5 : 0)
    }
}



struct RepeatedPlaceholderView: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<5) { _ in
                VStack(alignment: .leading) {
                    Text("Name")
                    Text("Environment")
                        .font(.subheadline)
                }
                .padding(.vertical, 10)
                .padding(.leading, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("Button"))
                .redacted(reason: .placeholder)
                .opacity(0.5)
            }
        }
    }
}
