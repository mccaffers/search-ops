// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

#if os(macOS)
struct macosDevelopView: View {
  @Binding var fullScreen : Bool
  @State var searchText = ""
  
  var body: some View {
    HStack {
      VStack {
        HStack {
          
          Text("API Queries")
            .font(.system(size: 22, weight:.light))
          
          
          
          Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 5)
        
        BetterTextEditor(text: $searchText, onClick:{})
        .textFieldStyle(PlainTextFieldStyle())
        .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
        .font(.system(size: 18))
        .background(Color("BackgroundAlt"))
        .clipShape(.rect(cornerRadius: 5))
        
      }
      .padding(.horizontal,10)
      .background(Color("BackgroundFixedShadow"))
      .clipShape(.rect(cornerRadius: 5))
      
      VStack {
        HStack {
          
          Text("Response")
            .font(.system(size: 22, weight:.light))
          
          
          
          Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 5)
        
        VStack(spacing:0){
          Text("Hello")
          Spacer()
        }
      }
      .padding(.horizontal,10)
      .background(Color("BackgroundFixedShadow"))
      .clipShape(.rect(cornerRadius: 5))
      
    }
    .padding(.leading, 3)
    .padding(.trailing, 5)
    .padding(.bottom, 5)
    .padding(.top, fullScreen ? 5 : 0)
  }
}


#endif
