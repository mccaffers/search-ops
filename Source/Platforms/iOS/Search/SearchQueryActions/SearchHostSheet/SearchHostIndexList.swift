// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct SearchHostIndexList: View {
    
    @Binding var selectedIndex: String
    @Binding var indexArray : [String]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var selectedHost: HostDetailsWrap
    
    var body: some View {
        ScrollView {
            
            VStack {
                
                
                Button {
                    selectedIndex="_all"
                    dismiss()
                } label: {
                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {
                        HStack {
                            Text("_all (All Indicies)")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .regular))
                            Spacer()
                        }
                        .padding(20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("Button"))
                    .cornerRadius(5)
                    .padding(.horizontal, 15)
                }.padding(.top, 10)
                
                
                if indexArray.count > 0 {
                    
                    ForEach(indexArray.sorted(by: <), id: \.self) {  index in
                        Button {
                            selectedIndex=index
                            dismiss()
                        } label: {
                            VStack(
                                alignment: .leading,
                                spacing: 10
                            ) {
                                HStack {
                                    Text("\(index)")
                                        .font(.system(size: 16, weight: .regular))
                                    Spacer()
                                }
                                .padding(20)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .background(selectedIndex == index ? Color("ButtonHighlighted") : Color("Button"))
                            .cornerRadius(5)
                            .padding(.horizontal, 15)
                        }
                    }
                }
            }
            .navigationTitle("Indicies")
            
        }
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
        .frame(maxWidth: .infinity)
    }
}
#endif
