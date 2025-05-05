// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

enum SearchQueryPickerState: Hashable {
    case QueryString
    case Compound
    case Custom
}


struct SearchQuerySheetPicker: View {
  
  @Binding var selection : SearchQueryPickerState
  
  @Environment(\.colorScheme) var colorScheme
  
  private func FontSize(_ input: SearchQueryPickerState) -> Font {
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
  
  private func TextColor(_ input: SearchQueryPickerState) -> Color {
    return Picker.foregroundBar(selection==input)
    
  }
  
  private func BarColor (_ input: SearchQueryPickerState) -> Color {
    
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
            selection=SearchQueryPickerState.QueryString
          }
        }, label: {
          
          VStack (spacing:5) {
            
            HStack(spacing:5) {
              Text("Input String")
            }
            .font(FontSize(.QueryString))
            .foregroundColor(TextColor(.QueryString))
            .overlay {
              RoundedRectangle(cornerRadius: 0)
                .fill(BarColor(.QueryString))
                .frame(height:2)
                .padding(.top, 30)
                .frame(maxWidth:BarWidth(selection==SearchQueryPickerState.QueryString))
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 10)
          .background(Picker.buttonBackground(selection==SearchQueryPickerState.QueryString))
          .cornerRadius(0)
          
          
        })
        
        Button(action: {
          withAnimation {
            selection=SearchQueryPickerState.Custom
          }
          
        }, label: {
          
          VStack (spacing:5) {
            
            HStack(spacing:3) {
              Text("Custom JSON")
            }
            .font(FontSize(.Custom))
            .foregroundColor(TextColor(.Custom))
            .overlay {
              RoundedRectangle(cornerRadius: 0)
                .fill(BarColor(.Custom))
                .frame(height:2)
                .padding(.top, 30)
                .frame(maxWidth:BarWidth(selection==SearchQueryPickerState.Custom))
            }
            
            
            
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 10)
          .background(Picker.buttonBackground(selection==SearchQueryPickerState.Custom))
          .cornerRadius(0)
          
        })
        
      }
      .accentColor(Color("TextColor"))
      .frame(height: 40)
      
    }
    .frame(maxWidth: .infinity, alignment:.leading)
  }
}
