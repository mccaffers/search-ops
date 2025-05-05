// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SearchQueryPrebuilt: View {
  
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    ScrollView {
      VStack(
        alignment: .leading,
        spacing: 10
      ) {
        
        SearchQuerySearchTermInput()
        
        VStack(alignment: .leading){
          
          Text("Query String Examples:")
            .font(.system(size: 16))
          
        }.padding(.horizontal, 15).padding(.top, 5)
        
        VStack(alignment: .leading){
          Text("error")
            .font(.system(size: 16))
          
          Text("Find documents with any values that contain error")
            .font(.system(size: 14, weight:.light))
          
        }.padding(.horizontal, 30)
        
        VStack(alignment: .leading){
          Text("status:error")
            .font(.system(size: 16))
          
          Text("Find documents where the status has a value of error")
            .font(.system(size: 14, weight:.light))
          
        }.padding(.horizontal, 30)
        
        VStack(alignment: .leading){
          Text("status:error AND environment:production")
            .font(.system(size: 16))
          
          Text("Find documents where the status has a value of error and the environment is production")
            .font(.system(size: 14, weight:.light))
          
        }.padding(.horizontal, 30)
        
        VStack(alignment: .leading){
          Text("city:(gotham OR atlantis)")
            .font(.system(size: 16))
          
          Text("Find documents where the city is either gotham or atlantis")
            .font(.system(size: 14, weight:.light))
          
        }.padding(.horizontal, 30)
        
        VStack(alignment: .leading){
          Text(verbatim: "_exists_:error")
          
            .font(.system(size: 16))
          
          Text("Find documents where the error field exists")
            .font(.system(size: 14, weight:.light))
          
        }.padding(.horizontal, 30)
        
        VStack(alignment: .leading){
          Text(verbatim: "price:[10 TO 1000]")
          
            .font(.system(size: 16))
          
          Text("Find a range values. **TO** must be in capital")
            .font(.system(size: 14, weight:.light))
          
        }.padding(.horizontal, 30)
           
      }
    }
  }
}
