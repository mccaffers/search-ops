// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import Search_Ops

// Indicates that this test class is only to be used with iOS 16.0.0 and above.
@available(iOS 16.0.0, *)
final class HostTests: XCTestCase {
  
  // Test to verify that a valid HTTPS host URL is correctly formatted.
  @MainActor
  func testValidHost() throws {
    // Sets up details for a hypothetical Elasticsearch host with HTTPS as the scheme.
    let esDetails = HostDetails()
    esDetails.host = HostURL()
    esDetails.host?.url = "example.com"
    esDetails.host?.port = "9201"
    esDetails.host?.scheme = HostScheme.HTTPS
    
    // Builds a full URL from the provided host details to check the URL formation logic.
    let formattedUrl = Request().buildUrl(esDetails, "")
    
    // Asserts that the URL is formed correctly according to the provided details.
    XCTAssertEqual(formattedUrl, "https://example.com:9201")
  }
  
  // Test to check URL building for a non-secure HTTP host without a port.
  @MainActor
  func testNonSecureHTTPHost() throws {
    // Configures host details for a non-secure HTTP connection without specifying a port.
    let esDetails = HostDetails()
    esDetails.host = HostURL()
    esDetails.host?.url = "example.com"
    esDetails.host?.port = ""
    esDetails.host?.scheme = HostScheme.HTTP
    
    // Builds the URL to verify that it defaults correctly when no port is specified.
    let formattedUrl = Request().buildUrl(esDetails, "")
    
    // Checks that the URL is correctly formatted without a port, defaulting to HTTP's standard port.
    XCTAssertEqual(formattedUrl, "http://example.com")
  }
  
  // Test to ensure that invalid port entries are handled gracefully, defaulting to ignore the invalid port.
  @MainActor
  func testNonSecureInvalidHTTPHost() throws {
    // Sets up host details with an invalid port value.
    let esDetails = HostDetails()
    esDetails.host = HostURL()
    esDetails.host?.url = "example.com"
    esDetails.host?.port = "-100"  // Invalid port number
    esDetails.host?.scheme = HostScheme.HTTP
    
    // Attempts to build the URL and checks how the system handles the invalid port.
    let formattedUrl = Request().buildUrl(esDetails, "")
    
    // Verifies that the URL ignores the invalid port and does not include it in the resulting string.
    XCTAssertEqual(formattedUrl, "http://example.com")
  }
  
  
  // Tests that pasted addresses are split into host, scheme and port
  func testHostAddressFromAWSConsole() {
    XCTAssertEqual(HostAddress.parse("https://search-logs-abc123.eu-west-2.es.amazonaws.com"),
                   HostAddress(host: "search-logs-abc123.eu-west-2.es.amazonaws.com", scheme: .HTTPS))
    XCTAssertEqual(HostAddress.parse("  https://search-x.eu-west-2.es.amazonaws.com/_dashboards/app/home#/  \n"),
                   HostAddress(host: "search-x.eu-west-2.es.amazonaws.com", scheme: .HTTPS))
    XCTAssertEqual(HostAddress.parse("HTTPS://Search-X.es.amazonaws.com:443/"),
                   HostAddress(host: "Search-X.es.amazonaws.com", scheme: .HTTPS, port: "443"))
  }
  
  func testHostAddressSchemesAndPorts() {
    XCTAssertEqual(HostAddress.parse("http://localhost:9200"), HostAddress(host: "localhost", scheme: .HTTP, port: "9200"))
    XCTAssertEqual(HostAddress.parse("http://example.com"), HostAddress(host: "example.com", scheme: .HTTP))
    XCTAssertEqual(HostAddress.parse("example.com:9200"), HostAddress(host: "example.com", port: "9200"))
    XCTAssertEqual(HostAddress.parse("example.com:"), HostAddress(host: "example.com"))
    XCTAssertEqual(HostAddress.parse("example.com/"), HostAddress(host: "example.com"))
    XCTAssertEqual(HostAddress.parse("https://example.com?pretty"), HostAddress(host: "example.com", scheme: .HTTPS))
  }
  
  func testHostAddressLeavesPlainHostsAlone() {
    XCTAssertEqual(HostAddress.parse("myhost.example.com"), HostAddress(host: "myhost.example.com"))
    XCTAssertEqual(HostAddress.parse("10.0.0.5"), HostAddress(host: "10.0.0.5"))
    XCTAssertEqual(HostAddress.parse("https"), HostAddress(host: "https"))
    XCTAssertEqual(HostAddress.parse(""), HostAddress(host: ""))
  }
  
  func testHostAddressIPv6() {
    XCTAssertEqual(HostAddress.parse("::1"), HostAddress(host: "::1"))
    XCTAssertEqual(HostAddress.parse("[::1]:9200"), HostAddress(host: "[::1]", port: "9200"))
    XCTAssertEqual(HostAddress.parse("http://[fe80::1]"), HostAddress(host: "[fe80::1]", scheme: .HTTP))
  }

}
