//
//  LimitObj.swift
//  PocketSearch
//
//  Created by Ryan McCaffery on 27/05/2023.
//

import Foundation

@available(iOS 13.0, *)
public class LimitObj: ObservableObject {
    
    public init(size: Int = 25) {
        self.size = size
    }
    
    @Published public var size: Int = 25
}
