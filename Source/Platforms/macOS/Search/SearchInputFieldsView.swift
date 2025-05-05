// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
struct macosTextFieldClearButton: ViewModifier {
    @Binding var fieldText: String

    func body(content: Content) -> some View {
        content
            .overlay {
                if !fieldText.isEmpty {
                    HStack {
                        Spacer()
                        Button {
                            fieldText = ""
                        } label: {
                            Image(systemName: "multiply.circle.fill")
                            .font(.system(size: 16))
                            .padding(8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(2)
                    }
                }
            }
    }
}



extension View {
    func showClearButton(_ text: Binding<String>) -> some View {
        self.modifier(macosTextFieldClearButton(fieldText: text))
    }
}


struct SearchInputFieldsView: View {
  
  @State var identifer = "searchbar"
  @State var selected : Bool = false
  
  var handleSubmit : () -> Void
  
  @Binding var searchText : String
  @FocusState var focusedField: String?
  @Binding var selection: macosSearchViewEnum
  
  @EnvironmentObject var filterObject : FilterObject
  @Binding var searchIndicator : Bool
  @State var rotationDegrees = 0.0
  
  @Binding var textFieldWidth : CGFloat
  
  var schedule: TimerInterval?
  
  var textFieldHeight : CGFloat = 42
  var componentHeight : CGFloat = 40
  
  var stopTimer : () -> ()
  
  func abbreviateTimeUnit(_ unit: TimeUnit) -> String {
    switch unit {
    case .milliseconds:
      return "ms"
    case .seconds:
      return "s"
    case .minutes:
      return "m"
    case .hours:
      return "h"
    }
  }
  
  @State var hoveringOverTimerButton = false
  
  func hoveringOverTimerButtonColor() -> Color {
    if schedule != nil {
      if hoveringOverTimerButton {
        return Color("WarnTextHighlighted")
      }
      return Color("WarnText")
    } else {
      return Color("Button")
    }
  }
  
  var body: some View {
    HStack(spacing:5) {
      
      
      CustomNSTextField(text: $searchText, onSubmit: handleSubmit)
        .focused($focusedField, equals: identifer)
        .textFieldStyle(PlainTextFieldStyle())
        .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
        .frame(height: textFieldHeight)
        .font(.system(size: 18))
        .background(Color("Button"))
        .clipShape(.rect(cornerRadius: 5))
        .overlay(
          RoundedRectangle(cornerRadius: 5)
            .stroke(selected ? Color("LabelBackgroundBorder") : Color("BackgroundAlt"), lineWidth: 1)
        )
        .onChange(of: focusedField, perform: { newValue in
          // selected the textfield view, needs a negative check on selected
          // or swiftui loops forever
          if newValue == identifer && !selected {
            selected = true
          } else if selected && newValue != identifer {
            selected = false
          }
        })
        .showClearButton($searchText)
        .background(
          GeometryReader { geometry in
            Color.clear
              .onAppear {
                textFieldWidth = geometry.size.width
              }
              .onChange(of: geometry.size.width) { newHeight in
                textFieldWidth = newHeight
              }
          }
        )
      
      
      Button {
        selection = .DatePeriod
      } label: {
        
        Group {
          if filterObject.dateField == nil {
            VStack {
              Text("Date Field")
              Text("Not set")
                .font(.footnote)
            }
          } else if filterObject.relativeRange != nil {
            HStack(spacing:2) {
              Text(filterObject.relativeRange?.value.string ?? "")
              Text(filterObject.relativeRange?.period.rawValue ?? "")
            }
          } else if filterObject.absoluteRange != nil {
            HStack(spacing:2) {
              
              if filterObject.absoluteRange?.fromNow ?? false {
                Text("Now")
              } else {
                Text(filterObject.absoluteRange?.from.formatted() ?? "")
              }
              Image(systemName: "arrow.right")
              if filterObject.absoluteRange?.toNow ?? false {
                Text("Now")
              } else {
                Text(filterObject.absoluteRange?.to.formatted() ?? "")
              }
            }
            
          } else {
            VStack {
              Text("Date Range")
              Text("Not set")
                .font(.footnote)
            }
          }
          
        }
        .padding(.horizontal, 10)
        .frame(height: componentHeight)
        .background(Color("Button"))
        .clipShape(.rect(cornerRadius: 5))
      }.buttonStyle(PlainButtonStyle())
      
      Button {
        handleSubmit()
      } label: {
        
        if searchIndicator {
          VStack (spacing:4) {
            
            Image(systemName: "arrow.triangle.2.circlepath")
              .font(.system(size: 24, weight:.light))
              .rotationEffect(Angle(degrees: self.rotationDegrees))
            
          }
          .frame(width: 60)
          .frame(height: componentHeight)
          .onAppear {
            rotationDegrees=0
            
            let baseAnimation = Animation.linear(duration: 0.8)
            let repeated = baseAnimation.repeatForever(autoreverses: false)
            
            withAnimation(repeated) {
              rotationDegrees = 360
            }
          }
          
          
          
        } else {
          Text("Search")
            .frame(width: 60)
            .frame(height: componentHeight)
        }
      }.buttonStyle(MyButtonStyle(color: Color("PositiveButton")))
      
      Button {
        
        if schedule == nil {
          selection = .SearchScreenRefreshFrequency
        } else {
          stopTimer()
        }
      } label: {
        HStack(spacing:0) {
          Image(systemName: "clock.arrow.2.circlepath")
            .font(.system(size: 20))
            .padding(.horizontal, schedule == nil ? 8 : 4)
          
          if let schedule = schedule {
            HStack(spacing:0) {
              Text(schedule.value.string)
              Text(abbreviateTimeUnit(schedule.unit))
            }
            .padding(.trailing, 4)
            
          }
          
        }
        .padding(.horizontal, 2)
        .frame(height: componentHeight)
        .background(hoveringOverTimerButtonColor())
        .clipShape(.rect(cornerRadius: 5))
      }
      .buttonStyle(PlainButtonStyle())
      .onHover { hover in
        hoveringOverTimerButton = hover
      }
    
      
      
    }.disabled(selection != .None)
  }
}

#endif
