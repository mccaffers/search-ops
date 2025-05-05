// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

enum FilterEnum: String {
    case Filters
    case Recent
}

struct DateQuery {
	var date : Date
	var field : SquashedFieldsArray
}
#if os(iOS)
struct QueryMainSheet: View {
  
  @Binding var selectedIndex: String
  @Binding var makeSearchRequest: Bool
  @Binding var showDateInputView : DateQuery?
  
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var orientation : Orientation
  
  @State var selection = FilterEnum.Filters
  
  
  var fields : [SquashedFieldsArray]
  
  var body: some View {
    NavigationStack {
      GeometryReader { reader in
        ScrollView {
          VStack(spacing:5) {
            
            if showDateInputView != nil {
              SearchQueryDatePopup(showDateInputView:$showDateInputView,
                                   fields:fields)
            } else if selection == .Filters {
              //              ScrollView {
              QueryStringCardView()
              QuerySheetRecentCard(selection:.constant(.Filters))
              
              //                    QueryExistsCard()
              //                QueryDateCardView(selectedIndex: $selectedIndex)
              //              }
              
            } else if selection == .Recent {
              QuerySheetRecentCard(selection:$selection)
            }
            
            Spacer()
            
            if !orientation.isLandscape {
              VStack {
                Image(systemName: "hand.draw")
                Text("Swipe down to close")
              }
              .frame(maxWidth: .infinity)
              .font(.footnote)
              .foregroundStyle(Color("TextSecondary"))
              .padding(.bottom, 10)
            }
            
            
          }.frame(minHeight: reader.size.height)
        }
      }
      .tint(Color("AccentColor"))
      .foregroundColor(Color("TextColor"))
      .background(Color("Background"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
      .navigationTitle("Filters")
      .toolbar {
        if orientation.isLandscape {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Close") {
              dismiss()
            }
            .tint(Color("AccentColor"))
            .foregroundColor(Color("TextColor"))
          }
        }
      }
      
      
    }
    .tint(Color("AccentColor"))
    
    //    .onAppear {
    //      
    //      UINavigationBar.appearance() .backgroundColor = UIColor(Color("BackgroundAlt"))
    //      UINavigationBar.appearance().tintColor = UIColor(Color("AccentColor"))
    //      
    //    }
    //    
    //    .onDisappear {
    //      UINavigationBar.appearance().backgroundColor = UIColor(Color("Background"))
    //    }
    
  }
}
#endif
