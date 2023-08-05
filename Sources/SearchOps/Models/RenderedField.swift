//
//  File.swift
//  
//
//  Created by Ryan McCaffery on 29/06/2023.
//

import Foundation

@available(iOS 15.0, *)
public class RenderedFields : ObservableObject {
    
    @Published
    public var fields: [SquasedFieldsArray]
    
    @Published
    public var id : UUID = UUID()
    
    public init(fields: [SquasedFieldsArray]) {
        self.fields = fields
    }
}
