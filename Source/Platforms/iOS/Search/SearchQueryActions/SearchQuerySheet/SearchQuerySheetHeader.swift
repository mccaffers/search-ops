// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)

struct SearchQuerySheetHeader: View {
    
    @Environment(\.dismiss) private var dismiss
//    @EnvironmentObject var queryObj : QueryObj
    @EnvironmentObject var orientation : Orientation
    
    var body: some View {
        
        VStack (spacing:0) {
            
            ZStack {
                HStack(
                    alignment: .center,
                    spacing: 2
                ) {
                    
                    Spacer()
                    
                    Text("Query Filter")
                        .font(.system(size: 28, weight: .light))
                    
                    Spacer()
                    
                }
                .padding(.trailing, 15)
                .frame(height:70)
             

                if orientation.orientation != .portrait {
                    HStack(
                        alignment: .center,
                        spacing: 2
                    ) {
                        Spacer()
                        
                        Button {
                            //                    queryObj.Clear()
                            dismiss()
                        } label: {
                            
                            VStack (spacing:0) {
                                
                                Text(Image(systemName: "x.circle"))
                                    .font(.system(size: 25))
                                    .foregroundColor(Color("TextColor"))
                                
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                        }
                        
                    }
                    .padding(.trailing, 15)
                    .frame(height:70)
                }
                
       
                
            }
        }
    }
}
#endif
