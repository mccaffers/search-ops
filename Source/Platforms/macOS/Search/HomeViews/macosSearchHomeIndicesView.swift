// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

#if os(macOS)
struct macosSearchHomeIndicesView: View {
  
  @Binding var localSelectedHost: HostDetails?
  @Binding var localSelectedIndex : String
  @Binding var indexArray : [String]
  
  @Binding var selectedHost: HostDetails?
  @Binding var selectedIndex: String
  @Binding var fields : [SquashedFieldsArray]
  
  @Binding var loadingIndices : Bool
  @Binding var indexError: ResponseError?
  
  @ObservedObject var localFilterObject: FilterObject
  
  var request : (_ selectedHost: HostDetails, _ selectedIndex: String, _ filterObject: FilterObject) -> ()
  var mappingsRequest : () async -> ()
  var updateIndexArray : () async -> ()
  
  @State var hoveringActiveButton = false
  @State private var indexFilterText: String = ""
  
  var trimmedFilter: String {
    indexFilterText.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  var filteredIndices: [String] {
    IndexFilterHelper.filter(indices: indexArray, query: indexFilterText)
  }
  
  var showAllButton: Bool {
    IndexFilterHelper.showAllButton(query: indexFilterText)
  }
  
  var body: some View {
    
    VStack (alignment:.leading, spacing:5){
      
      HStack {
        if !trimmedFilter.isEmpty && localSelectedIndex.isEmpty {
          let count = filteredIndices.count + (showAllButton ? 1 : 0)
          let total = IndexFilterHelper.totalCount(indices: indexArray)
          Text("Indices (\(count) of \(total))")
            .font(.subheadline)
            .foregroundStyle(Color("TextSecondary"))
        } else {
          Text("Indices")
            .font(.subheadline)
            .foregroundStyle(Color("TextSecondary"))
        }
        Spacer()
      }
      
      if indexError != nil {
        HStack {
          HStack {
            Image(systemName: "exclamationmark.triangle")
              .foregroundStyle(.red)
              .font(.system(size: 20))
            VStack(alignment: .leading, spacing:3) {
              Text(indexError?.title ?? "Error")
              Text(indexError?.message ?? "")
            }
          }
          .padding(.vertical, 10)
          .padding(.horizontal, 15)
          .background(Color("BackgroundAlt"))
          .clipShape(.rect(cornerRadius: 5))
          Button {
            Task {
              await updateIndexArray()
            }
          } label: {
            VStack(spacing:5) {
              Image(systemName: "arrow.triangle.2.circlepath")
              Text("Retry")
            }
            .padding(10)
            .background(Color("Button"))
            .clipShape(.rect(cornerRadius: 5))
          }.buttonStyle(PlainButtonStyle())

        }
      } else if loadingIndices {
        HStack {
          ProgressView()
            .scaleEffect(0.7)
            .padding(.vertical, 2)
            .padding(.horizontal, 5)
          Text("Loading indices")
            .font(.subheadline)
          
        }
      } else if !localSelectedIndex.isEmpty {
        HStack {
          Button(action: {
            withAnimation {
              localSelectedIndex = ""
              indexFilterText = ""
              localFilterObject.clear()
              fields = []
            }
          }) {
            Text(localSelectedIndex)
              .padding(10)
              .background(Color("Background"))
              .clipShape(.rect(cornerRadius: 5))
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .onHover { hover in
            hoveringActiveButton = hover
          }
          if hoveringActiveButton {
            Image(systemName: "xmark.circle")
              .bold()
              .padding(.leading, -15)
              .padding(.top, -25)
          }
        }
      } else {
        if !indexArray.isEmpty {
          HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
              .foregroundColor(Color("TextSecondary"))
              .font(.system(size: 11))
            
            TextField("Filter indices...", text: $indexFilterText)
              .textFieldStyle(PlainTextFieldStyle())
              .font(.system(size: 13))
              .disableAutocorrection(true)
              #if os(macOS)
              .onExitCommand {
                indexFilterText = ""
              }
              #endif
            
            if !indexFilterText.isEmpty {
              Button(action: {
                indexFilterText = ""
              }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(Color("TextSecondary"))
                  .font(.system(size: 12))
              }
              .buttonStyle(PlainButtonStyle())
              .help("Clear filter")
            }
          }
          .padding(.horizontal, 8)
          .frame(height: 32)
          .frame(maxWidth: 320)
          .background(Color("Button"))
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .overlay(
            RoundedRectangle(cornerRadius: 5)
              .stroke(Color("BackgroundAlt"), lineWidth: 1)
          )
          .padding(.bottom, 4)
        }
        
        if !showAllButton && filteredIndices.isEmpty {
          HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
              .foregroundColor(Color("TextSecondary"))
            Text("No indices matching \"\(trimmedFilter)\"")
              .foregroundColor(Color("TextSecondary"))
              .font(.subheadline)
          }
          .padding(.vertical, 8)
        } else {
          WrappingHStack(horizontalSpacing: 5) {
            if showAllButton {
              Button(action: {
                indexFilterText = ""
                withAnimation {
                  localSelectedIndex = "_all"
                }
              }) {
                Text("_all")
                  .padding(10)
                  .background(Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
                  .contentShape(Rectangle())
              }.buttonStyle(PlainButtonStyle())
            }
            
            ForEach(filteredIndices, id: \.self) { indexName in
              Button(action: {
                indexFilterText = ""
                withAnimation {
                  localSelectedIndex = indexName
                }
                
                Task {
                  // mappings request
                  await mappingsRequest()
                }
              }) {
                Text(indexName)
                  .padding(10)
                  .background(localSelectedIndex == indexName ? Color("ButtonHighlighted") : Color("Button"))
                  .clipShape(.rect(cornerRadius: 5))
                  .contentShape(Rectangle())
              }.buttonStyle(PlainButtonStyle())
            }
          }
        }
      }
    }
    .onChange(of: localSelectedHost?.id) { _ in
      indexFilterText = ""
    }
    .onChange(of: indexArray) { _ in
      indexFilterText = ""
    }
  }
}

public struct IndexFilterHelper {
  public static func matches(indexName: String, query: String) -> Bool {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return true }
    if trimmed.contains("*") || trimmed.contains("?") {
      var sanitized = trimmed
      while sanitized.contains("**") {
        sanitized = sanitized.replacingOccurrences(of: "**", with: "*")
      }
      let pattern = "^" + NSRegularExpression.escapedPattern(for: sanitized)
        .replacingOccurrences(of: "\\*", with: ".*")
        .replacingOccurrences(of: "\\?", with: ".") + "$"
      if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
        let range = NSRange(location: 0, length: indexName.utf16.count)
        return regex.firstMatch(in: indexName, options: [], range: range) != nil
      }
    }
    return indexName.localizedCaseInsensitiveContains(trimmed)
  }
  
  public static func filter(indices: [String], query: String) -> [String] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let sorted = Array(Set(indices.filter { $0 != "_all" })).sorted(by: <)
    guard !trimmed.isEmpty else {
      return sorted
    }
    return sorted.filter { matches(indexName: $0, query: trimmed) }
  }
  
  public static func showAllButton(query: String) -> Bool {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return true }
    return matches(indexName: "_all", query: trimmed)
  }
  
  public static func totalCount(indices: [String]) -> Int {
    let uniqueIndices = Set(indices.filter { $0 != "_all" })
    return uniqueIndices.count + 1
  }
}
#endif
