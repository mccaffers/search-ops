// SearchOps Source Code
// UI macOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI

struct SideBarWrapper {
  var sender : SideBarFlow = .Flow
  var item : macosSearchSideBarEnum
}

enum SideBarFlow {
  case Flow
  case User
}

enum macosSearchSideBarEnum: Hashable {
  case None
  case Hosts
  case Indices
  case DateTypePicker
  case Sort
  case Fields
}

#if os(macOS)
struct macosSearchSideBar: View {
  
  @Binding var fields : [SquashedFieldsArray]
  @Binding var onlyVisibleFields : [SquashedFieldsArray]
  @Binding var selectedHost: HostDetails?
  @Binding var selectedIndex: String
  @Binding var updatedFieldsNotification : UUID
  @Binding var renderedObjects: RenderObject?
  @Binding var fieldOrder: [String]
  var dateFieldKey: String?
  /// The data view's field labels
  var labels: [String: String] = [:]
  @State var refresh : UUID?
  @EnvironmentObject var hostsUpdated : HostUpdatedNotifier
//  @Binding var sidebar : sideBar
  var searchIndicator : Bool
  var Request: () -> Void
  @State var fieldsSearchtext = ""
  @State var refreshFields = UUID()
  
  func convertToSlidingScale(_ value: Double) -> Double {
      // Ensure the input is within the expected range
      guard value >= 0 && value <= 10 else {
          return -1 // Return an invalid value to indicate out of range input
      }
      // Linear transformation formula
      return 0.5 - (value * 0.05)
  }

  @State var fieldListMode: FieldListMode = .mapped

  var fieldCount: Int {
    switch fieldListMode {
    case .mapped: return fields.count
    case .inDocuments: return onlyVisibleFields.count
    case .selected: return fields.filter { $0.visible }.count
    }
  }

  var body: some View {
    
    VStack(alignment: .leading) {

          
      
      ZStack {
        if fields.count == 0 {
          
          VStack {
            ForEach(0..<11) { number in
              HStack {
                RoundedRectangle(cornerRadius: 5)
                  .fill(Color("BackgroundAlt"))
                  .frame(maxWidth: 30)
                RoundedRectangle(cornerRadius: 5)
                  .fill(Color("BackgroundAlt"))
                  .frame(maxWidth: .infinity)
                RoundedRectangle(cornerRadius: 5)
                  .fill(Color("BackgroundAlt"))
                  .frame(maxWidth: 30)
              }.frame(maxHeight: 30)
                .opacity(convertToSlidingScale(Double(number)))
            }
            Spacer()
          }.padding(.leading, 10)
       
        } else {
          VStack (spacing:5){
  
            HStack {

              HStack(alignment: .bottom, spacing:4){
                Text(fieldListMode.title)
                Text(fieldCount.string)
                  .font(.footnote)
                  .foregroundStyle(Color("TextSecondary"))
              }.padding(.leading, 2)
             
              Spacer()
              
              HStack(spacing: 2) {
                ForEach(FieldListMode.allCases, id: \.self) { mode in
                  Button {
                    fieldListMode = mode
                    refreshFields = UUID()
                  } label: {
                    Image(systemName: mode.systemImage)
                      .font(.system(size: 12))
                      .frame(width: 26, height: 26)
                      .background(fieldListMode == mode ? Color("BackgroundAlt3") : Color.clear)
                      .clipShape(.rect(cornerRadius: 4))
                      .contentShape(Rectangle())
                  }
                  .buttonStyle(PlainButtonStyle())
                  .help(mode.help)
                }
              }
              .padding(2)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
           
            }
            .padding(.top, 5)
            
            HStack(spacing: 6) {
              TextField("", text: $fieldsSearchtext)
                .textFieldStyle(PlainTextFieldStyle())

              if !fieldsSearchtext.isEmpty {
                Button(action: {
                  fieldsSearchtext = ""
                }) {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color("TextSecondary"))
                    .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Clear search")
              }
            }
              .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
              .frame(height: 30)
              .background(Color("Button"))
              .clipShape(.rect(cornerRadius: 5))
              .overlay(
                RoundedRectangle(cornerRadius: 5)
                  .stroke(Color("BackgroundAlt"), lineWidth: 1)
              )
              .frame(maxWidth: .infinity)
            
            
            macosSearchFieldSheetView(loading: searchIndicator,
                                      selectedIndex: selectedIndex,
                                      fields: $fields,
                                      updatedFieldsNotification: $updatedFieldsNotification,
                                      onlyVisibleFields: $onlyVisibleFields,
                                      mode: fieldListMode,
                                      fieldsSearchtext: $fieldsSearchtext,
                                      fieldOrder: $fieldOrder,
                                      dateFieldKey: dateFieldKey,
                                      labels: labels)
            .id(refreshFields)
           

          }
          .padding(.horizontal, 5)
          .background(Color("BackgroundAlt"))
          .clipShape(.rect(cornerRadius: 5))
          .padding(.trailing, 5)
        }
  
      }
//       
//  
//      HStack {
//        Button {
//          welcomeScreen = true
//        } label: {
//          Image(systemName: "house.fill")
//            .font(.system(size: 16))
//            .padding(8)
//            .background(Color("Button"))
//            .clipShape(.rect(cornerRadius: 5))
//        }
//        .buttonStyle(PlainButtonStyle())
//        
//        Button {
//          sidebar = .settings
//        } label: {
//          Text("Settings")
//            .frame(maxWidth: .infinity)
//            .padding(10)
//            .background(Color("Button"))
//            .clipShape(.rect(cornerRadius: 5))
//        }
//        .buttonStyle(PlainButtonStyle())
//   
//      }
//      .padding(.leading, 10)
      
      Spacer()
      
    }
//    .border(.red)
    .id(refresh)
    .onChange(of: hostsUpdated.updated) { newValue in
      refresh = UUID()
    }
    .onChange(of: updatedFieldsNotification) { _ in
      refreshFields = UUID()
    }
    .environmentObject(HostDetailsWrap(item: selectedHost))
  }
}

#endif
