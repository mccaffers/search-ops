// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import RealmSwift

@testable import Search_Ops

// HostDetails as it was at schema version 6, before the AWS SigV4 fields.
// Maps onto the same table name and stays out of the default schema.
class HostDetailsV6: Object {
  @Persisted(primaryKey: true) var id: UUID
  @Persisted var name: String = ""
  @Persisted var cloudid: String = ""
  @Persisted var host: HostURL? = HostURL()
  @Persisted var env: String = ""
  @Persisted var username: String = ""
  @Persisted var password: String = ""
  @Persisted var authToken: String = ""
  @Persisted var apiToken: String = ""
  @Persisted var apiKey: String = ""
  @Persisted var version: String = ""
  @Persisted var customHeaders: List<Headers>
  @Persisted var draft: Bool = true
  @Persisted var createdDate: Date = Date.now
  @Persisted var updatedDate: Date = Date.now
  @Persisted var softDelete: Bool = false
  @Persisted var detachedID: UUID = UUID()
  @Persisted var connectionType = ConnectionType.CloudID
  @Persisted var authenticationType = AuthenticationTypes.None

  override class func _realmObjectName() -> String { return "HostDetails" }
  override class func shouldIncludeInDefaultSchema() -> Bool { return false }
}

final class HostDetailsMigrationTests: XCTestCase {

  private var fileURL: URL!

  override func setUp() {
    super.setUp()
    // Each test gets its own file, nothing shared on disk
    fileURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("HostDetailsMigrationTests-\(UUID().uuidString).realm")
  }

  override func tearDown() {
    _ = try? Realm.deleteFiles(for: Realm.Configuration(fileURL: fileURL))
    super.tearDown()
  }

  private func config(version: UInt64, hostType: Object.Type) -> Realm.Configuration {
    // The app's own migration block
    return Realm.Configuration(fileURL: fileURL,
                               schemaVersion: version,
                               migrationBlock: RealmManager.migrationBlock,
                               objectTypes: [hostType, HostURL.self, Headers.self])
  }

  func testVersion6HostUpgradesWithEmptyAWSFields() throws {
    let id = UUID()

    try autoreleasepool {
      let realm = try Realm(configuration: config(version: 6, hostType: HostDetailsV6.self))
      let legacy = HostDetailsV6()
      legacy.id = id
      legacy.name = "Legacy"
      legacy.connectionType = .URL
      legacy.host?.url = "search.example.com"
      legacy.username = "elastic"
      legacy.password = "secret"
      legacy.authenticationType = .UsernamePassword
      try realm.write {
        realm.add(legacy)
      }
    }

    // The new fields change the schema, so version 6 can no longer open it
    try autoreleasepool {
      XCTAssertThrowsError(try Realm(configuration: config(version: 6, hostType: HostDetails.self)))
    }

    try autoreleasepool {
      let realm = try Realm(configuration: config(version: RealmManager.schemaVersion, hostType: HostDetails.self))
      let host = try XCTUnwrap(realm.object(ofType: HostDetails.self, forPrimaryKey: id))

      XCTAssertEqual(host.name, "Legacy")
      XCTAssertEqual(host.username, "elastic")
      XCTAssertEqual(host.password, "secret")
      XCTAssertEqual(host.authenticationType, .UsernamePassword)
      XCTAssertEqual(host.awsAccessKeyId, "")
      XCTAssertEqual(host.awsSecretAccessKey, "")
      XCTAssertEqual(host.awsSessionToken, "")
      XCTAssertEqual(host.awsRegion, "")
      XCTAssertEqual(host.awsService, .es)

      // generateCopy reads every field, as the app does before async work
      XCTAssertEqual(host.generateCopy().awsService, .es)
    }
  }

  func testAWSFieldsPersist() throws {
    let id = UUID()

    try autoreleasepool {
      let realm = try Realm(configuration: config(version: RealmManager.schemaVersion, hostType: HostDetails.self))
      let host = HostDetails()
      host.id = id
      host.name = "OpenSearch"
      host.authenticationType = .AWSSigV4
      host.awsAccessKeyId = "AKIDEXAMPLE"
      host.awsSecretAccessKey = "secret"
      host.awsSessionToken = "token"
      host.awsRegion = "eu-west-2"
      host.awsService = .aoss
      try realm.write {
        realm.add(host, update: .modified)
      }
    }

    try autoreleasepool {
      let realm = try Realm(configuration: config(version: RealmManager.schemaVersion, hostType: HostDetails.self))
      let host = try XCTUnwrap(realm.object(ofType: HostDetails.self, forPrimaryKey: id))

      XCTAssertEqual(host.authenticationType, .AWSSigV4)
      XCTAssertEqual(host.awsAccessKeyId, "AKIDEXAMPLE")
      XCTAssertEqual(host.awsSecretAccessKey, "secret")
      XCTAssertEqual(host.awsSessionToken, "token")
      XCTAssertEqual(host.awsRegion, "eu-west-2")
      XCTAssertEqual(host.awsService, .aoss)
    }
  }
}
