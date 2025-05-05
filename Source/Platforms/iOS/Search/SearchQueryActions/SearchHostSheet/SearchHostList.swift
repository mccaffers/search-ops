// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(iOS)
struct SearchHostList: View {
    
    @EnvironmentObject var selectedHost: HostDetailsWrap
    @EnvironmentObject var serverObjects : HostsDataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
        
            VStack {
                
                ForEach(serverObjects.items, id: \.self) {  index in
                    Button {
                        selectedHost.item = index
                        dismiss()
                    } label: {
                        VStack(
                            alignment: .leading,
                            spacing: 10
                        ) {
                            HStack {
                                VStack(
                                    alignment: .leading,
                                    spacing: 5
                                ) {
                                    Text("\(index.name)")
                                        .font(.system(size: 20, weight: .regular))
                                    Text("\(index.env)")
                                }
                                Spacer()
                                VStack(
                                    alignment: .center,
                                    spacing: 5
                                ) {
                                    Text("Version")
                                    Text("\(index.version)")
                                }

                            }
                            .padding(20)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .background(selectedHost.item?.id == index.id ? Color("ButtonHighlighted") : Color("Button"))
                        .cornerRadius(5)
                        .padding(.horizontal, 15)
                    }
                }
                
//                Button {
//                    selectedHost.item = nil
//                    dismiss()
//                } label: {
//                    VStack(
//                        alignment: .leading,
//                        spacing: 10
//                    ) {
//                        Text("Clear")
//                            .padding(10)
//                    }
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .background(Color("WarnButton"))
//                    .cornerRadius(5)
//                    .padding(.horizontal, 15)
//                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color("BackgroundAlt"), for: .navigationBar)
            .navigationTitle("Hosts")
            .padding(.top, 10)
        }
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
        .frame(maxWidth: .infinity)
    }
}
#endif
