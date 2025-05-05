// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI


struct DateRangeSheetHeader: View {
    
//    @EnvironmentObject var dateObj : DateRangeObj
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack (spacing:0) {
                     
            
            ZStack {
                
                HStack(
                    alignment: .center,
                    spacing: 2
                ) {
                    
                    Spacer()
                    
                    Text("Date Range")
                        .font(.system(size: 28, weight: .light))
                    
                    Spacer()
                    
                }
                .frame(height:70)
                .padding(.trailing, 15)
                
//                if dateObj.valid {
//                    
//                    
//                    HStack(
//                        alignment: .center,
//                        spacing: 2
//                    ) {
//                        
//                        Spacer()
//                        
//                        Button {
//                            
//                            dismiss()
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                                dateObj.ResetObj()
//                            }
//                        } label: {
//                            
//                            VStack (spacing:0) {
//                                HStack {
//                                    Text("Clear")
//                                    //                                Text(Image(systemName: "trash"))
//                                    //                                    .font(.system(size: 22))
//                                }
//                                .foregroundColor(Color("TextColor"))
//                            }
//                            .padding(10)
//                            .background(Color("WarnButton"))
//                            .cornerRadius(5)
//                            
//                        }
//                        
//                        
//                    }
//                    .padding(.trailing, 15)
//                    .frame(height:70)
//                    
//                }
            }
        }
    }
}
