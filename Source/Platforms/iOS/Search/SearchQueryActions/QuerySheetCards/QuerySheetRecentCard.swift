// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct QuerySheetRecentCard: View {
  
  @StateObject var saveFilteredObj = FilterHistoryDataManager()
  
  @Binding var selection : FilterEnum
  
  @EnvironmentObject var filterObject : FilterObject
  
  @Environment(\.dismiss) private var dismiss
  
  var savedFilteredObjs: [RealmFilterObject] {
    saveFilteredObj.items
      .filter { !$0.isInvalidated }
      .filter { $0.query?.values.count ?? 0 > 0 }
  }
  
  var body: some View {
    VStack {
      
      HStack(alignment: .bottom){
        Text("Recent Queries")
          .font(.system(size: 24, weight:.bold))
        Spacer()
        if savedFilteredObjs.count > 0 {
          Text("Showing last 10")
            .font(.system(size: 13))
            .foregroundStyle(Color("TextSecondary"))
        }
      }
      .frame(maxWidth: .infinity, alignment:.leading)
      .padding(.bottom, 5)
      
      if savedFilteredObjs.count > 0 {
        
        VStack (spacing:10) {
          
          ForEach(savedFilteredObjs.sorted {$0.date > $1.date }.prefix(10), id:\.id) { item in
            
            if !item.isInvalidated,
               let queryObj = item.query,
               let compound = item.query?.compound,
               queryObj.values.count > 0 {
              
              VStack(spacing:5) {
                Text(item.date.formatted())
                  .font(.system(size: 13))
                  .foregroundStyle(Color("TextSecondary"))
                  .frame(maxWidth: .infinity, alignment:.leading)
                
                
                Button {
                  
                  filterObject.query = queryObj.eject()
                  
                } label: {
                  
                  VStack(spacing:0) {
                    
                    if queryObj.values.count > 1 {
                      Text(compound.rawValue)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment:.leading)
                      
                      
                    }
                    
                    
                    ForEach(queryObj.values, id:\.self) { queryItem in
                      
                      HStack {
                        if queryObj.values.count > 1 {
                          Text(" | -")
                            .foregroundColor(Color("TextSecondary"))
                            .fontWeight(.ultraLight)
                        }
                        
                        Group {
                          if queryItem.string == "*" {
                            Text("* (wildcard)")
                          } else {
                            Text(queryItem.string)
                              .frame(maxWidth: .infinity, alignment: .leading)
                              .multilineTextAlignment(.leading)
                          }
                        }
                        .frame(alignment:.leading)
                        
                      }.frame(maxWidth: .infinity, alignment:.leading)
                      
                    }
                  }
                  .frame(maxWidth: .infinity, alignment:.leading)
                  .padding(.horizontal, 10)
                  .padding(.vertical, 5)
                  .foregroundStyle(.white)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
                  .transaction { transaction in
                    transaction.animation = nil
                  }
                }
              }
              
            }
            
          }
          
          
        }
      } else {
        VStack {
          Text("No recent searches")
            .padding(.vertical, 50)
        }
        .frame(maxWidth: .infinity)
        .background(Color("Background"))
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .padding(.horizontal, 15)
    .background(Color("BackgroundAlt"))
    .cornerRadius(5)
    .padding(.horizontal, 10)
    .padding(.top, 10)
    
  }
}
