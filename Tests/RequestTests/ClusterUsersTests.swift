// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

@available(iOS 16.0.0, *)
final class ClusterUsersTests: XCTestCase {

  // MARK: Elasticsearch GET /_security/user

  func testParseElasticsearchUsers() throws {
    let body = """
    {
      "kibana_system": {
        "username": "kibana_system", "roles": ["kibana_system"], "full_name": null, "email": null,
        "metadata": { "_reserved": true }, "enabled": true
      },
      "Alice": {
        "username": "Alice", "roles": ["viewer", "editor"], "full_name": "Alice Smith", "email": "alice@example.com",
        "metadata": {}, "enabled": false
      },
      "bob": {
        "username": "bob", "roles": [], "full_name": "  ", "metadata": {}, "enabled": true
      }
    }
    """

    let users = try XCTUnwrap(ClusterUsers.parse(body, source: .elasticsearch))

    XCTAssertEqual(users.map(\.username), ["Alice", "bob", "kibana_system"])

    let alice = users[0]
    XCTAssertEqual(alice.fullName, "Alice Smith")
    XCTAssertEqual(alice.email, "alice@example.com")
    XCTAssertEqual(alice.roles, ["viewer", "editor"])
    XCTAssertFalse(alice.enabled)
    XCTAssertFalse(alice.reserved)

    XCTAssertNil(users[1].fullName, "Blank names are dropped")
    XCTAssertTrue(users[1].roles.isEmpty)

    XCTAssertTrue(users[2].reserved)
    XCTAssertTrue(users[2].enabled)
  }

  // MARK: OpenSearch GET /_plugins/_security/api/internalusers

  func testParseOpenSearchUsers() throws {
    let body = """
    {
      "admin": {
        "hash": "", "reserved": true, "hidden": false, "backend_roles": ["admin"],
        "attributes": {}, "description": "Demo admin user", "opendistro_security_roles": [], "static": false
      },
      "logstash": {
        "hash": "", "reserved": false, "hidden": false, "backend_roles": ["logstash"],
        "attributes": {}, "opendistro_security_roles": ["logstash_role"], "static": false
      }
    }
    """

    let users = try XCTUnwrap(ClusterUsers.parse(body, source: .openSearch))

    XCTAssertEqual(users.map(\.username), ["admin", "logstash"])
    XCTAssertEqual(users[0].description, "Demo admin user")
    XCTAssertEqual(users[0].backendRoles, ["admin"])
    XCTAssertTrue(users[0].reserved)
    XCTAssertTrue(users[0].enabled)
    XCTAssertEqual(users[1].roles, ["logstash_role"])
    XCTAssertFalse(users[1].reserved)
  }

  func testParseEmptyObjectIsNoUsers() throws {
    let users = try XCTUnwrap(ClusterUsers.parse("{}", source: .elasticsearch))
    XCTAssertTrue(users.isEmpty)
  }

  func testParseRejectsErrorsAndNonObjects() {
    let error = """
    {"error":{"root_cause":[{"type":"security_exception","reason":"Security must be explicitly enabled"}],"type":"security_exception","reason":"Security must be explicitly enabled"},"status":500}
    """
    XCTAssertNil(ClusterUsers.parse(error, source: .elasticsearch))
    XCTAssertNil(ClusterUsers.parse("[]", source: .elasticsearch))
    XCTAssertNil(ClusterUsers.parse("not json", source: .openSearch))
    XCTAssertNil(ClusterUsers.parse(#"{"status":"OK","message":"x"}"#, source: .openSearch))
  }

  func testErrorReason() {
    let elastic = """
    {"error":{"root_cause":[{"type":"security_exception","reason":"action [cluster:admin/xpack/security/user/get] is unauthorized"}]},"status":403}
    """
    XCTAssertEqual(ClusterUsers.errorReason(elastic), "action [cluster:admin/xpack/security/user/get] is unauthorized")
    XCTAssertEqual(ClusterUsers.errorReason(#"{"status":"FORBIDDEN","message":"No permission to access REST API"}"#),
                   "No permission to access REST API")
    XCTAssertNil(ClusterUsers.errorReason("plain text"))
  }

  // MARK: Falling back from Elasticsearch to OpenSearch

  func testElasticEndpointMissing() {
    for status in [400, 404, 405] {
      var result = ClusterUsersResult()
      result.httpStatus = status
      XCTAssertTrue(ClusterUsers.elasticEndpointMissing(result), "\(status)")
    }
    for status in [401, 403, 500] {
      var result = ClusterUsersResult()
      result.httpStatus = status
      XCTAssertFalse(ClusterUsers.elasticEndpointMissing(result), "\(status)")
    }
  }
}
