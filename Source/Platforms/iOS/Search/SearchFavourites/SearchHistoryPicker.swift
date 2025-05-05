// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

enum HistoryState: Hashable {
    case Recent
    case Favourites
}

struct SearchHistoryPicker: View {
    
    @Binding var selection : HistoryState
        
    @Environment(\.colorScheme) var colorScheme
    
    private func FontSize(_ input: HistoryState) -> Font {
        if input == selection {
            return .system(size: 18, weight:.regular)
        } else {
            return .system(size: 18, weight:.regular)
        }
    }
    
    private func BarWidth(_ input: Bool) -> CGFloat {
        if input {
            return 0
        } else {
            return 0
        }
    }
       
    private func TextColor(_ input: HistoryState) -> Color {
            return Picker.foregroundBar(selection==input)
        
    }
    
    private func BarColor (_ input: HistoryState) -> Color {
        
            return Picker.button(selection==input)
        
    }
    
    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            
            
            
            HStack(
                alignment: .center,
                spacing: 0
            )  {
                
                Button(action: {
                    withAnimation {
                        selection = HistoryState.Recent
                    }
                }, label: {
                    
                        VStack (spacing:5) {
                            
                            HStack(spacing:5) {
//                                Text(Image(systemName: "keyboard"))
                                Text("Recent")
                            }
                            .font(FontSize(.Recent))
                            .foregroundColor(TextColor(.Recent))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(BarColor(.Recent))
                                        .frame(height:2)
                                        .padding(.top, 30)
                                        .frame(maxWidth:BarWidth(selection==HistoryState.Recent))
                                }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Picker.buttonBackground(selection==HistoryState.Recent))
                        .cornerRadius(0)
                        
                    
                })
                
                Button(action: {
                    withAnimation {
                        selection=HistoryState.Favourites
                    }
                    
                }, label: {
                    
                    VStack (spacing:5) {
                        
                        HStack(spacing:3) {
                            Text("Favourites")
                        }
                        .font(FontSize(.Favourites))
                        .foregroundColor(TextColor(.Favourites))
                        .overlay {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(BarColor(.Favourites))
                                .frame(height:2)
                                .padding(.top, 30)
                                .frame(maxWidth:BarWidth(selection==HistoryState.Favourites))
                        }
                        
                      
                        
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Picker.buttonBackground(selection==HistoryState.Favourites))
                    .cornerRadius(0)
                    
                })
     
                
                
            }
            .accentColor(Color("TextColor"))
            .frame(height: 40)

        }
        .frame(maxWidth: .infinity, alignment:.leading)

        
    }
}


