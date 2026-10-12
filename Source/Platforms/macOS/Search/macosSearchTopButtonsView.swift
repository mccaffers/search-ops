// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------
import SwiftUI

#if os(macOS)
struct macosSearchTopButtonsView: View {
  
  @Binding var macosSearchRouterPath : macosSearchRouterPath
  @Binding var selection: macosSearchViewEnum
  @Binding var showFilterSidebar :  Bool
 
  var hostName : String? = nil
  var index: String? = nil
  /// Shown instead of the index when the search is a data view's pattern
  var dataView: DataView? = nil
  var latency: Duration? = nil
  /// The search's matching document count, shown when there's no histogram to show it
  var hitCountLabel: String? = nil
  /// The Save button and its popover, shown after the latency
  var saveControl: AnyView? = nil
  @Binding var currentWidth: CGFloat
  
    var body: some View {
      VStack {
        HStack (spacing: 5){
          
          Button {
            selection = .None
            macosSearchRouterPath = .WelcomeScreen
          } label: {
            Image(systemName: "house")
              .font(.system(size: 16))
              .padding(5)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }.buttonStyle(PlainButtonStyle())
          
          
          Button {
            selection = (selection == .Hosts ? .None : .Hosts)
          } label: {
            Group {
              if let name = hostName {
                Text(name)
              } else {
                Text("Host")
              }
            }
              .padding(6)
              .background(selection == .Hosts ? Color("BackgroundAlt") : Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }.buttonStyle(PlainButtonStyle())
          
          
          Button {
            selection = (selection == .Indices ? .None : .Indices)
          } label: {
            Group {
              if let dataView = dataView {
                HStack(spacing: 5) {
                  Image(systemName: "rectangle.stack")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color("LabelBackgroundFocus"))
                  Text(dataView.name)
                }
              } else if let index = index {
                Text(index)
              } else {
                Text("Index")
              }
            }
              .padding(6)
              .background(selection == .Indices ? Color("BackgroundAlt") : Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .overlay(
                RoundedRectangle(cornerRadius: 5)
                  .stroke(Color("LabelBackgroundFocus"), lineWidth: dataView == nil ? 0 : 1)
              )
              .contentShape(Rectangle())
          }.buttonStyle(PlainButtonStyle())
          .help(dataView.map { "Data view \($0.name): \($0.pattern)" } ?? (index ?? "Choose an index"))
          Spacer()

          if let hitCountLabel = hitCountLabel {
            Text(hitCountLabel)
              .monospacedDigit()
              .padding(6)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .help("Documents matching the last search")
          }

          if let latency = latency {
            let latencyColor: Color = latency.isSlowLatency ? .orange : .green
            Text(latency.latencyLabel)
              .monospacedDigit()
              .foregroundColor(latencyColor)
              .padding(6)
              .background(latencyColor.opacity(0.18))
              .clipShape(.rect(cornerRadius: 5))
              .help("Round-trip time of the last search request")
          }

          if let saveControl = saveControl {
            saveControl
          }

          Button {
            showFilterSidebar.toggle()
            if showFilterSidebar {
              currentWidth = 300
            }
          } label: {
            
            Group {
              if showFilterSidebar {
                HStack{
                  Image(systemName: "arrow.right")
                  Text("Hide Fields")
                }
              } else {
                HStack{
                  Image(systemName: "arrow.left")
                  Text("Show Fields")
                }
              }
            }
              .padding(6)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          
        }.padding(.trailing, 5)
      }
    }
}

/// Saves the search to the Saved tab. It turns green for a moment with `confirmation`, eg. "Saved", and shows a dot
/// while the saved search it came from has changes to update.
struct macosSaveSearchButton: View {
  /// eg. "Saved" or "Updated", shown for a moment afterwards
  let confirmation: String?
  let hasChanges: Bool
  let isOpen: Bool
  let action: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 5) {
        Image(systemName: confirmation == nil ? "bookmark" : "checkmark")
        Text(confirmation ?? "Save")
        if hasChanges && confirmation == nil {
          Circle()
            .fill(Color("LabelBackgroundFocus"))
            .frame(width: 6, height: 6)
            .accessibilityLabel("Has changes")
        }
      }
      .foregroundColor(confirmation == nil ? Color("TextColor") : .white)
      .padding(6)
      .background(confirmation != nil
                  ? Color("PositiveButton")
                  : (isHovered || isOpen ? Color("ButtonHighlighted") : Color("Button")))
      .clipShape(.rect(cornerRadius: 5))
      .contentShape(Rectangle())
      .animation(.easeInOut(duration: 0.15), value: confirmation)
    }
    .buttonStyle(PlainButtonStyle())
    .help(hasChanges
          ? "This search has changed since it was saved"
          : "Save this search, with its filters, columns and time period, to the Saved tab")
    .onHover { hovering in
      isHovered = hovering
    }
  }
}

#endif
