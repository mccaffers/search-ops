// SearchOps Source Code
// UI iOS Presentation Logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import SwiftUI
import UniformTypeIdentifiers
import Charts

struct GridData: Identifiable, Equatable {
    let id: Int
}

class Model: ObservableObject {
    @Published var data: [GridData]

    let columns = [
        GridItem(.adaptive(minimum: .infinity)),
        GridItem(.adaptive(minimum: .infinity))
    ]

    init() {
        data = Array(repeating: GridData(id: 0), count: 6)
        for i in 0..<data.count {
            data[i] = GridData(id: i)
        }
    }
}

//MARK: - Grid

struct DemoDragRelocateView: View {
    @StateObject private var model = Model()

    @State private var dragging: GridData?

    var body: some View {
   

            
            ScrollView {
                RoundedRectangle(cornerRadius: 0)
                    .fill(.clear)
                    .frame(minHeight: 2)
                
                LazyVGrid(columns: model.columns, spacing: 18) {
                    ForEach(model.data) { d in
                        GridItemView(d: d)
                        //.overlay(dragging?.id == d.id ? Color.white.opacity(0.8) : Color.clear)
                            .onDrag {
                                self.dragging = d
                                return NSItemProvider(object: String(d.id) as NSString)
                            }
                            .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: d, listData: $model.data, current: $dragging))
                    }
                }
                .padding(.horizontal, 10)
                .animation(.default, value: model.data)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .onDrop(of: [UTType.text], delegate: DropOutsideDelegate(current: $dragging))
        

    }
}

struct DragRelocateDelegate: DropDelegate {
    let item: GridData
    @Binding var listData: [GridData]
    @Binding var current: GridData?

    func dropEntered(info: DropInfo) {
        if let current = current, item != current {
            let from = listData.firstIndex(of: current)!
            let to = listData.firstIndex(of: item)!
            if listData[to].id != current.id {
                listData.move(fromOffsets: IndexSet(integer: from),
                    toOffset: to > from ? to + 1 : to)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        self.current = nil
        return true
    }
}

//MARK: - GridItem

struct GridItemView: View {
    var d: GridData

    var body: some View {
        VStack {
            Chart {
                BarMark(
                    x: .value("Mount", "jan/22"),
                    y: .value("Value", 5)
                )
                BarMark(
                    x: .value("Mount", "fev/22"),
                    y: .value("Value", 4)
                )
                BarMark(
                    x: .value("Mount", "mar/22"),
                    y: .value("Value", 7)
                )
            }
            
//            .frame(height: 250)
            
//            Text(String(d.id))
//                .font(.headline)
//                .foregroundColor(.white)
        }
        .frame(height: 150)
//        .background(Color.green)
    }
}

struct DropOutsideDelegate: DropDelegate {
    @Binding var current: GridData?
        
    func performDrop(info: DropInfo) -> Bool {
        current = nil
        return true
    }
}
