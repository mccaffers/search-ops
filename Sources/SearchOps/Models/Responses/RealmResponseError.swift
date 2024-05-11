// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import RealmSwift

@available(macOS 13.0, *)
@available(iOS 15, *)
public class RealmResponseError : EmbeddedObject {
  @Persisted public var title: String
  @Persisted public var message: String
  @Persisted public var type : ErrorResponseType
}
