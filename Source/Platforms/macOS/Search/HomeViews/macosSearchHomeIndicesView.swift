// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct macosSearchHomeIndicesView: View {
  
  @Binding var localSelectedHost: HostDetails?
  @Binding var localSelectedIndex : String
  @Binding var indexArray : [String]
  
  @Binding var selectedHost: HostDetails?
  @Binding var selectedIndex: String
  @Binding var fields : [SquashedFieldsArray]
  
  @Binding var loadingIndices : Bool
  @Binding var indexError: ResponseError?
  
  @ObservedObject var localFilterObject: FilterObject
  
  var request : (_ selectedHost: HostDetails, _ selectedIndex: String, _ filterObject: FilterObject) -> ()
  var mappingsRequest : () async -> ()
  var updateIndexArray : () async -> ()
  
  @State var hoveringActiveButton = false
  var body: some View {
    
    VStack (alignment:.leading, spacing:5){
      
      HStack {
        Text("Indices")
          .font(.subheadline)
          .foregroundStyle(Color("TextSecondary"))
          
        //          Text("/aliases")
        //            .font(.subheadline)
        //            .foregroundStyle(Color("TextSecondary"))
        //            .padding(.horizontal, 8)
        //            .padding(.vertical, 2)
        //            .background(Color("Background"))
        //            .clipShape(.rect(cornerRadius: 5))
        Spacer()
      }
      
      if indexError != nil {
        HStack {
          HStack {
            Image(systemName: "exclamationmark.triangle")
              .foregroundStyle(.red)
              .font(.system(size: 20))
            VStack(alignment: .leading, spacing:3) {
              Text(indexError?.title ?? "Error")
              Text(indexError?.message ?? "")
            }
          }
          .padding(.vertical, 10)
          .padding(.horizontal, 15)
          .background(Color("BackgroundAlt"))
          .clipShape(.rect(cornerRadius: 5))
          Button {
            Task {
              await updateIndexArray()
            }
          } label: {
            VStack(spacing:5) {
              Image(systemName: "arrow.triangle.2.circlepath")
              Text("Retry")
            }
            .padding(10)
            .background(Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
          }.buttonStyle(PlainButtonStyle())

        }
      } else if loadingIndices {
        HStack {
          ProgressView()
            .scaleEffect(0.7)
            .padding(.vertical, 2)
            .padding(.horizontal, 5)
          Text("Loading indices")
            .font(.subheadline)
          
        }
      } else if !localSelectedIndex.isEmpty {
        HStack {
          Button(action: {
            withAnimation {
              localSelectedIndex = ""
              localFilterObject.clear()
              fields = []
            }
          }) {
            Text(localSelectedIndex)
              .padding(10)
              .background(Color("Background"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .onHover { hover in
            hoveringActiveButton = hover
          }
          if hoveringActiveButton {
            Image(systemName: "xmark.circle")
              .bold()
              .padding(.leading, -15)
              .padding(.top, -25)
          }
        }
      } else {
        WrappingHStack(horizontalSpacing: 5) {
          
          Button(action: {
            localSelectedIndex = "_all"
            
          }) {
            Text("_all")
              .padding(10)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }.buttonStyle(PlainButtonStyle())
          
          let sortedIndex = indexArray.sorted(by: <)
          
          ForEach(sortedIndex.indices, id: \.self) { index in
            Button(action: {
              withAnimation {
                localSelectedIndex = sortedIndex[index]
              }
              
              Task {
                
                // mappings request
                
                await mappingsRequest()
                
              }
            }) {
              Text(sortedIndex[index])
                .padding(10)
                .background(localSelectedIndex == sortedIndex[index] ? Color("ButtonHighlighted") : Color("Button"))
                .clipShape(.rect(cornerRadius: 5))
                .contentShape(Rectangle())
            }.buttonStyle(PlainButtonStyle())
          }
        }
      }
    }
    
  }
}
