// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
#if os(iOS)
struct DetailViewPicker: View {
    
    @Binding var selection : DocumentDetailState
        
    @Environment(\.colorScheme) var colorScheme
    
    private func FontSize(_ input: DocumentDetailState) -> Font {
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
       
    private func TextColor(_ input: DocumentDetailState) -> Color {
            return Picker.foregroundBar(selection==input)
        
    }
    
    private func BarColor (_ input: DocumentDetailState) -> Color {
        
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
//                    withAnimation {
                        selection=DocumentDetailState.Fields
//                    }
                }, label: {
                    
                        VStack (spacing:5) {
                            
                            HStack(spacing:5) {
//                                Text(Image(systemName: "keyboard"))
                                Text("Fields")
                            }
                            .font(FontSize(.Fields))
                            .foregroundColor(TextColor(.Fields))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(BarColor(.Fields))
                                        .frame(height:2)
                                        .padding(.top, 30)
                                        .frame(maxWidth:BarWidth(selection==DocumentDetailState.Fields))
                                }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Picker.buttonBackground(selection==DocumentDetailState.Fields))
                        .cornerRadius(0)
                        
                    
                })
                
                Button(action: {
//                    withAnimation {
                        selection=DocumentDetailState.JSON
//                    }
                    
                }, label: {
                    
                    VStack (spacing:5) {
                        
                        HStack(spacing:3) {
                            Text("JSON")
                        }
                        .font(FontSize(.JSON))
                        .foregroundColor(TextColor(.JSON))
                        .overlay {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(BarColor(.JSON))
                                .frame(height:2)
                                .padding(.top, 30)
                                .frame(maxWidth:BarWidth(selection==DocumentDetailState.JSON))
                        }
                        
                      
                        
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Picker.buttonBackground(selection==DocumentDetailState.JSON))
                    .cornerRadius(0)
                    
                })
     
                
                
            }
            .accentColor(Color("TextColor"))
            .frame(height: 40)

        }
        .frame(maxWidth: .infinity, alignment:.leading)

        
    }
}


#endif
