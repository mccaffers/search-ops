import Foundation

public protocol KeychainManagerProtocol {
  func query() -> Data?
  @discardableResult func add(input:Data?) throws -> Data?
  func delete() throws
}





