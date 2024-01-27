// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2023 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import SwiftyJSON

@testable import SearchOps

@available(iOS 16.0.0, *)
final class HostTests: XCTestCase {
  
  @MainActor 
  func testValidHost() throws {
    
    // Test Host
    let esDetails = HostDetails()
    esDetails.host = HostURL()
    esDetails.host?.url = "example.com"
    esDetails.host?.port = "443"
    esDetails.host?.scheme = HostScheme.HTTPS
    
    // Check the Build URL function
    let formattedUrl = Request().buildUrl(esDetails, "")
    
    XCTAssertEqual(formattedUrl, "https://example.com:443")
  }
  
  @MainActor
  func testNonSecureHTTPHost() throws {
    
    // Test Host
    let esDetails = HostDetails()
    esDetails.host = HostURL()
    esDetails.host?.url = "example.com"
    esDetails.host?.port = ""
    esDetails.host?.scheme = HostScheme.HTTP
    
    // Check the Build URL function
    let formattedUrl = Request().buildUrl(esDetails, "")
    
    XCTAssertEqual(formattedUrl, "http://example.com")
  }
  
}
