// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI


enum SearchDateTimePicker: Hashable {
    case Relative
    case Absolute
    case Unknown
}


#if os(iOS)
struct SearchQueryPicker: View {
    
    @Binding var selection: SearchDateTimePicker
    
//    @EnvironmentObject var dateObj : DateRangeObj
    @EnvironmentObject var filterObject : FilterObject
    
    @State var fieldPickerAnimation : Int = 0
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var orientation : Orientation
    
       func FontSize(_ input: SearchDateTimePicker) -> Font {
        if input == selection {
            return .system(size: 18, weight:.regular)
        } else {
            return .system(size: 18, weight:.regular)
        }
    }
    
    func BarWidth(_ input: Bool) -> CGFloat {
        if input {
            return 0
        } else {
            return 0
        }
    }
    

    
    func TextColor(_ input: SearchDateTimePicker) -> Color {
            return Picker.foregroundBar(selection==input)
        
    }
    
    func BarColor (_ input: SearchDateTimePicker) -> Color {
//        if dateObj.valid  || input == .Field {
//            return Picker.button(selection==input)
//        } else {
//            return Color("InactiveButtonBackground")
//        }
        
        return .clear
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
                    
                    
                    Task {
//                        filterObject.absoluteRange = nil
//                        filterObject.relativeRange = RelativeRangeFilter()
                    }
                    
//                    if AllowRelativeAndAbsoluteViews() {
                        withAnimation(.easeIn(duration: 0.2)) {
                            selection=SearchDateTimePicker.Relative
                        }
//                    } else {
//                        withAnimation(.default) {
//                            fieldPickerAnimation += 1
//                        }
//                    }
                }, label: {
                    
                    
                    VStack (spacing:5) {
                        Text("Relative")
                            .font(FontSize(SearchDateTimePicker.Relative))
                            .foregroundColor(TextColor(SearchDateTimePicker.Relative))
                        
        
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
                    .background(Picker.buttonBackground(selection==SearchDateTimePicker.Relative))
                    .cornerRadius(0)
                    
                })
                .frame(maxWidth: .infinity, alignment: .center)
                
                Button(action: {
                    
                    Task {
//                        filterObject.absoluteRange = AbsoluteDateRangeObject()
//                        filterObject.relativeRange = nil
                    }
//                    if AllowRelativeAndAbsoluteViews() {
                        withAnimation(.easeIn(duration: 0.2)) {
                            selection=SearchDateTimePicker.Absolute
                        }
//                    } else {
//                        withAnimation(.default) {
//                            fieldPickerAnimation += 1
//                        }
//                    }
                }, label: {
                    
                    VStack (spacing:5) {
                        
                        Text("Absolute")
                            .font(FontSize(SearchDateTimePicker.Absolute))
                            .foregroundColor(TextColor(SearchDateTimePicker.Absolute))
                        
                       
                            
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
                    .background(Picker.buttonBackground(selection==SearchDateTimePicker.Absolute))
                    .cornerRadius(0)
                })
                .frame(maxWidth: .infinity, alignment: .center)
            
//                if orientation.isLandscape {
//                    Button {
//                        //                    queryObj.Clear()
//                        dismiss()
//                    } label: {
//                        
//                        VStack (spacing:0) {
//                            
//                            Text(Image(systemName: "x.circle"))
//                                .font(.system(size: 26))
//                                .foregroundColor(Color("TextColor"))
//                            
//                        }
//                        .padding(.vertical, 5)
//                        .padding(.horizontal, 10)
//                    }
//                }
            }
            .accentColor(Color("TextColor"))
            .frame(maxWidth: .infinity, alignment: .leading)
            
//            Rectangle()
//                .fill(Color("Background"))
//                .frame(maxWidth: .infinity)
//                .frame(height:5)
            
            
           
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
    }
}
#endif
