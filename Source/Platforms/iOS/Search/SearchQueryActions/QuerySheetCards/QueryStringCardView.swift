// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct QueryStringCardView: View {
  
  @State var showingQueryView = false
  @EnvironmentObject var filterObject : FilterObject
  
  var body: some View {
    Button {
      showingQueryView = true
    } label: {
      
      
      VStack(alignment: .leading, spacing:10){
        HStack (alignment:.center) {
          
          
          VStack(spacing:0) {
            HStack {
              Text("Query String")
                .font(.system(size: 24, weight:.bold))
              
              if let queryObj = filterObject.query {
                Button {
                  filterObject.query = nil
                } label: {
                  VStack(
                    alignment: .leading,
                    spacing: 10
                  ) {
                    Text("Clear")
                      .font(.system(size: 16))
                  }
                  .padding(.vertical, 8)
                  .padding(.horizontal, 10)
                  .foregroundColor(.white)
                  .background(Color("WarnButton"))
                  .cornerRadius(5)
                }
                Spacer()
              } else {
                HStack(spacing:3) {
                  Text("Not Set")
                }
                .padding(8)
                .foregroundColor(Color("TextColor"))
                .background(Color("LabelBackgrounds"))
                .cornerRadius(5)
              }
              
              
              Spacer()
              
              Image(systemName: "chevron.right")
                .font(.system(size: 22))
                .foregroundColor(Color("LabelBackgrounds"))
              
            }.frame(height: 40)
            
            if let queryObj = filterObject.query?.values {
              
              if let compound = filterObject.query?.compound,
                 filterObject.query?.values.count ?? 0 > 1 {
                Text(compound.rawValue)
                  .fontWeight(.bold)
                  .frame(maxWidth: .infinity, alignment:.leading)
                  .padding(.top, 5)
              }
              
              
              ForEach(queryObj.indices, id: \.self) { index in
                HStack {
                  if filterObject.query?.values.count ?? 0 > 1 {
                    Text(" | -")
                      .foregroundColor(Color("TextSecondary"))
                      .fontWeight(.ultraLight)
                  }
                  Group {
                    if queryObj[index].string == "*" {
                      Text("* (wildcard)")
                    } else {
                      Text(queryObj[index].string)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    }
                  }
                  //                                        .font(.system(size: 14, weight:.regular))
                  .frame(alignment:.leading)
                  //
                  
                }.padding(.top, 10)
                  .frame(maxWidth: .infinity, alignment:.leading)
              }
              //                                    .padding(.vertical, 10)
              
            }
          }
          
          Spacer()
          
          
          
        }.frame(maxWidth: .infinity)
        
        
        if filterObject.query == nil {
          
          Text("Quick Buttons:")
            .font(.system(size: 14))
          
          HStack {
            Button {
              filterObject.query = QueryObject()
              filterObject.query?.values.append(QueryFilterObject(string: "*"))
              
            } label: {
              VStack(
                alignment: .leading,
                spacing: 10
              ) {
                
                Text("* (wildcard)")
                
              }
              .padding(.vertical, 10)
              .frame(maxWidth: .infinity)
              .foregroundColor(.white)
              .background(Color("Button"))
              .cornerRadius(5)
            }
            .frame(maxWidth: .infinity)
            
            Button {
              filterObject.query = QueryObject()
              filterObject.query?.values.append(QueryFilterObject(string: "success"))
            } label: {
              VStack(
                alignment: .leading,
                spacing: 10
              ) {
                Text("success")
                
              }
              .padding(.vertical, 10)
              .frame(maxWidth: .infinity)
              .foregroundColor(.white)
              .background(Color("Button"))
              .cornerRadius(5)
            }
            .frame(maxWidth: .infinity)
            
            Button {
              filterObject.query = QueryObject()
              filterObject.query?.values.append(QueryFilterObject(string: "error"))
            } label: {
              VStack(
                alignment: .leading,
                spacing: 10
              ) {
                Text("error")
                
              }
              .padding(.vertical, 10)
              .frame(maxWidth: .infinity)
              .foregroundColor(.white)
              .background(Color("Button"))
              .cornerRadius(5)
            }
            .frame(maxWidth: .infinity)
            
            
            
            
          }
          
          
        }
        
      }.padding(.bottom, 10)
      
      
      
      
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .padding(.horizontal, 15)
    .background(Color("BackgroundAlt"))
    .cornerRadius(5)
    .padding(.horizontal, 10)
    .padding(.top, 10)
    .navigationDestination(isPresented:$showingQueryView, destination: {
      SearchQuerySheetView()
    })
  }
}
