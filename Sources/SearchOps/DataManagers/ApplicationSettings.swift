// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(iOS 15, *)
public class ApplicationSettings : Object {

  @Persisted(primaryKey: true) public var id: UUID = UUID()
  
  // Search Settings
  @Persisted public var maximumDocumentsPerPage : Int = 25
  @Persisted public var requestTimeout : Int = 15

}
