// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation
import SwiftyJSON

/// Which security API answered the users request
public enum ClusterUserSource: String {
  case elasticsearch = "Elasticsearch"
  case openSearch = "OpenSearch"

  public var endpoint: String {
    switch self {
    case .elasticsearch:
      return "/_security/user"
    case .openSearch:
      return "/_plugins/_security/api/internalusers"
    }
  }
}

/// A user from the cluster's native (Elasticsearch) or internal (OpenSearch) user database
public struct ClusterUser: Identifiable, Equatable {
  public var id: String { username }
  public let username: String
  public let fullName: String?
  public let email: String?
  public let description: String?
  public let roles: [String]
  public let backendRoles: [String]
  public let enabled: Bool
  public let reserved: Bool
}

public struct ClusterUsersResult {
  public var users: [ClusterUser] = []
  public var source: ClusterUserSource? = nil
  public var httpStatus: Int = 0
  public var error: ResponseError? = nil
}

@available(macOS 13.0, *)
@available(iOS 16.0.0, *)
public class ClusterUsers {

  /// Lists the users on the cluster, read only.
  /// Hosts don't record whether they're Elasticsearch or OpenSearch, so the Elasticsearch
  /// security API is tried first and the OpenSearch security plugin API second.
  @MainActor
  public static func listUsers(serverDetails: HostDetails) async -> ClusterUsersResult {
    let elastic = await request(serverDetails: serverDetails, source: .elasticsearch)
    // Succeeded, or the host couldn't be reached at all
    if elastic.error == nil || elastic.httpStatus == 0 {
      return elastic
    }

    let openSearch = await request(serverDetails: serverDetails, source: .openSearch)
    if openSearch.error == nil {
      return openSearch
    }

    // Elasticsearch answered properly but refused (eg. security disabled, 403), so its error is
    // the meaningful one. An unknown endpoint (400/404/405) means it's probably OpenSearch.
    return elasticEndpointMissing(elastic) ? openSearch : elastic
  }

  @MainActor
  private static func request(serverDetails: HostDetails, source: ClusterUserSource) async -> ClusterUsersResult {
    let clock = ContinuousClock()
    var response = ServerResponse()

    let timeTaken = await clock.measure {
      response = await Request().invoke(serverDetails: serverDetails, endpoint: source.endpoint)
      if let data = response.data {
        response.parsed = String(bytes: data, encoding: .utf8) ?? ""
      }
    }
    response.duration = timeTaken

    await Logger.event(response: response, host: serverDetails)

    var result = ClusterUsersResult()
    result.source = source
    result.httpStatus = response.httpStatus

    if let error = response.error {
      result.error = error
      return result
    }

    let body = response.parsed?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    if response.httpStatus >= 400 {
      let message = errorReason(body) ?? (body.isEmpty ? "Request failed with HTTP status \(response.httpStatus)" : body)
      result.error = ResponseError(title: "HTTP Error \(response.httpStatus)", message: message, type: .critical)
      return result
    }

    guard let users = parse(body, source: source) else {
      result.error = ResponseError(title: "Response Error",
                                   message: errorReason(body) ?? "Invalid JSON response received from host",
                                   type: .critical)
      return result
    }

    result.users = users
    return result
  }

  static func elasticEndpointMissing(_ result: ClusterUsersResult) -> Bool {
    return [400, 404, 405].contains(result.httpStatus)
  }

  /// Parses a users response keyed by username, sorted by name.
  /// Returns nil when the body isn't a JSON object of users, eg. an error document.
  public static func parse(_ body: String, source: ClusterUserSource) -> [ClusterUser]? {
    guard let data = body.data(using: .utf8),
          let json = try? JSON(data: data),
          let users = json.dictionary,
          json["error"] == JSON.null,
          users.values.allSatisfy({ $0.type == .dictionary }) else {
      return nil
    }

    return users.map { username, user in
      switch source {
      case .elasticsearch:
        return ClusterUser(
          username: user["username"].string ?? username,
          fullName: nonEmpty(user["full_name"].string),
          email: nonEmpty(user["email"].string),
          description: nil,
          roles: user["roles"].arrayValue.compactMap { $0.string },
          backendRoles: [],
          enabled: user["enabled"].bool ?? true,
          reserved: user["metadata"]["_reserved"].bool ?? false
        )
      case .openSearch:
        return ClusterUser(
          username: username,
          fullName: nil,
          email: nil,
          description: nonEmpty(user["description"].string),
          roles: user["opendistro_security_roles"].arrayValue.compactMap { $0.string },
          backendRoles: user["backend_roles"].arrayValue.compactMap { $0.string },
          enabled: true,
          reserved: user["reserved"].bool ?? false
        )
      }
    }
    .sorted { $0.username.localizedStandardCompare($1.username) == .orderedAscending }
  }

  /// Pulls the reason out of an Elasticsearch/OpenSearch error document
  static func errorReason(_ body: String) -> String? {
    guard let data = body.data(using: .utf8), let json = try? JSON(data: data) else { return nil }
    if let reason = json["error"]["root_cause"][0]["reason"].string ?? json["error"]["reason"].string {
      return reason
    }
    return json["error"].string ?? json["message"].string
  }

  private static func nonEmpty(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
    return value
  }
}
