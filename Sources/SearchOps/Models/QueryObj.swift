//
//  QueryObject.swift
//  PocketSearch
//
//  Created by Ryan on 04/02/2023.
//

import Foundation

@available(iOS 13.0, *)
class QueryObj: ObservableObject {
    @Published var queryString: String = "*"
    
    func Clear() {
        self.queryString = "*"
    }
}
