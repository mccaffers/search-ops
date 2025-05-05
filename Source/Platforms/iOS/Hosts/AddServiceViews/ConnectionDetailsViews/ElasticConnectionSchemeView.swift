// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import RealmSwift

struct AddHostConnectionSchemeView: View {
  
  @Binding var localScheme: HostScheme
  
  private func highlightButton(_ input: HostScheme) -> Color {
    if input == localScheme {
      return Color("ButtonHighlighted")
    } else {
      return Color("Button")
    }
  }
  
  @Environment(\.colorScheme) var colorScheme
  
  private func foregroundColor(_ input: HostScheme) -> Color {
    return Color("ButtonText")
  }
  
  var body: some View {
    VStack (spacing:0) {
      
      HStack (spacing:0)  {
        
        Button {
          localScheme = HostScheme.HTTPS
        } label: {
          ZStack {
            Text("https")
              .font(.system(size:15))
              .frame(maxWidth: .infinity, maxHeight:.infinity)
              .foregroundColor(foregroundColor(HostScheme.HTTPS))
              .background(highlightButton(HostScheme.HTTPS))
#if os(iOS)
              .cornerRadius(5, corners: [.topLeft, .bottomLeft])
#endif
            
            VStack(
              alignment: .center,
              spacing: 0
            ) {
              if localScheme == HostScheme.HTTPS {
                Spacer()
                Circle()
                  .fill(foregroundColor(HostScheme.HTTPS))
                  .frame(width: 2.5, height: 2.5)
                  .padding(.bottom, 3)
              }
            }
          }.frame(height:38)
          
        }
        .frame(maxWidth: .infinity, maxHeight:.infinity)
        
        Button {
          localScheme = HostScheme.HTTP
        } label: {
          ZStack {
            Text("http")
              .font(.system(size:15))
              .frame(maxWidth: .infinity, maxHeight:.infinity)
              .foregroundColor(foregroundColor(HostScheme.HTTP))
              .background(highlightButton(HostScheme.HTTP))
#if os(iOS)
              .cornerRadius(5, corners: [.topRight, .bottomRight])
#endif
            VStack(
              alignment: .center,
              spacing: 0
            ) {
              if localScheme == HostScheme.HTTP {
                Spacer()
                Circle()
                  .fill(foregroundColor(HostScheme.HTTP))
                  .frame(width: 2.5, height: 2.5)
                  .padding(.bottom, 3)
              }
            }
          }.frame(height:38)
        }
        .frame(maxWidth: .infinity, maxHeight:.infinity)
      }
      .background(Color("MultipleChoiceBtn"))
      .cornerRadius(5)
      .frame(maxWidth: .infinity, alignment: .leading)
 
    }
    
//    .onAppear {
//      localScheme = host.scheme
//    }
//    .onChange(of: host, perform: { newValue in
//      print(newValue)
//    })
    .onChange(of: localScheme, perform: { newValue in
      //            let realm = try! Realm()
      //            try! realm.write {
      //                host.scheme = newValue
      //            }
//      item.host?.scheme = newValue
//      HostsDataManager.setScheme(item: item, scheme: newValue)
    })
    .padding(.bottom, 5)
    .frame(height: 38)
  }
}
//
//struct AddHostConnectionSchemeView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddHostConnectionSchemeView()
//    }
//}
