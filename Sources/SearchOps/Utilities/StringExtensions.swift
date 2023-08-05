// SearchOps Swift Package
// Business logic for SearchOps iOS Application
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)

import Foundation

extension String {
    var isInt: Bool {
        return Int(self) != nil
    }
}

extension StringProtocol {
    var data: Data { Data(utf8) }
    var base64Encoded: Data { data.base64EncodedData() }
    var base64Decoded: Data? { Data(base64Encoded: string) }
}

extension LosslessStringConvertible {
    var string: String { .init(self) }
}

extension Sequence where Element == UInt8 {
    var data: Data { .init(self) }
    var base64Decoded: Data? { Data(base64Encoded: data) }
    var string: String? { String(bytes: self, encoding: .utf8) }
}

