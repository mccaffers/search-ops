// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest
import RealmSwift

@testable import Search_Ops

class HostDetailsTests: XCTestCase {
  
  func testAuthenticationTypeDidSetWithPrePopulatedData() {
    let hostDetails = HostDetails()
    
    // Populate with initial data
    hostDetails.apiKey = "apiKey"
    
    // Test setting to APIKey
    hostDetails.authenticationType = .APIKey
    XCTAssertTrue(hostDetails.username.isEmpty && hostDetails.password.isEmpty && hostDetails.authToken.isEmpty && hostDetails.apiToken.isEmpty, "APIKey setting did not clear other fields properly with pre-populated data")
    
    // Reset initial data
    hostDetails.authToken = "token"
    
    // Test setting to AuthToken
    hostDetails.authenticationType = .AuthToken
    XCTAssertTrue(hostDetails.username.isEmpty && hostDetails.password.isEmpty && hostDetails.apiKey.isEmpty && hostDetails.apiToken.isEmpty, "AuthToken setting did not clear other fields properly with pre-populated data")
    
    // Reset initial data
    hostDetails.username = "user"
    hostDetails.password = "pass"
    
    // Test setting to UsernamePassword
    hostDetails.authenticationType = .UsernamePassword
    XCTAssertTrue(hostDetails.authToken.isEmpty && hostDetails.apiKey.isEmpty && hostDetails.apiToken.isEmpty, "UsernamePassword setting did not clear other fields properly with pre-populated data")
    
    // Reset initial data
    hostDetails.apiToken = "apiToken"
    
    // Test setting to APIToken
    hostDetails.authenticationType = .APIToken
    XCTAssertTrue(hostDetails.authToken.isEmpty && hostDetails.apiKey.isEmpty && hostDetails.username.isEmpty && hostDetails.password.isEmpty, "APIToken setting did not clear other fields properly with pre-populated data")
  }
  
  
  func testEquality() {
    let header1 = LocalHeaders(id: UUID(), header: "Content-Type", value: "application/json")
    let header2 = LocalHeaders(id: header1.id, header: "Content-Type", value: "application/json")
    let header3 = LocalHeaders(id: UUID(), header: "Content-Type", value: "application/json")
    
    // Test for equality with the same ID
    XCTAssertEqual(header1, header2, "Headers with the same ID should be equal")
    
    // Test for inequality with different IDs
    XCTAssertNotEqual(header1, header3, "Headers with different IDs should not be equal")
    
    // Test for inequality with same fields but different IDs
    let header4 = LocalHeaders(id: UUID(), header: header1.header, value: header1.value)
    XCTAssertNotEqual(header1, header4, "Headers with different IDs but same other fields should not be equal")
  }
  
  func testIsValid() {
    let hostDetails = HostDetails()
    
    // Test case 1: Everything is empty
    XCTAssertFalse(hostDetails.isValid(), "HostDetails should be invalid when all fields are empty")
    
    // Test case 2: Valid name, no cloudid or host URL
    hostDetails.name = "ValidName"
    XCTAssertFalse(hostDetails.isValid(), "HostDetails should be invalid when there is no cloudid or host URL even if the name is valid")
    
    // Test case 3: Valid name, valid cloudid, no host URL
    hostDetails.cloudid = "ValidCloudID"
    XCTAssertTrue(hostDetails.isValid(), "HostDetails should be valid when name and cloudid are valid even without host URL")
    
    // Test case 4: Valid name, no cloudid, valid host URL
    hostDetails.cloudid = ""
    hostDetails.host = HostURL()  // Ensure host is not nil
    hostDetails.host?.url = "https://example.com"
    XCTAssertTrue(hostDetails.isValid(), "HostDetails should be valid when name and host URL are valid even without cloudid")
    
    // Test case 5: Empty name, valid cloudid, valid host URL
    hostDetails.name = ""
    XCTAssertFalse(hostDetails.isValid(), "HostDetails should be invalid when name is empty even if cloudid and host URL are valid")
  }
  
  
  
  func testGenerateCopy() {
    let original = HostDetails()
    setupOriginalHostDetails(original)
    
    let copy = original.generateCopy()
    
    // Test copied values
    XCTAssertEqual(original.id, copy.detachedID, "DetachedID of the copy should match the ID of the original")
    XCTAssertEqual(original.name, copy.name, "Name should be the same in the copy")
    XCTAssertEqual(original.cloudid, copy.cloudid, "CloudID should be the same in the copy")
    XCTAssertEqual(original.host?.url, copy.host?.url, "Host URL should be the same in the copy")
    XCTAssertEqual(original.env, copy.env, "Environment should be the same in the copy")
    XCTAssertEqual(original.username, copy.username, "Username should be the same in the copy")
    XCTAssertEqual(original.password, copy.password, "Password should be the same in the copy")
    XCTAssertEqual(original.authToken, copy.authToken, "AuthToken should be the same in the copy")
    XCTAssertEqual(original.apiToken, copy.apiToken, "APIToken should be the same in the copy")
    XCTAssertEqual(original.apiKey, copy.apiKey, "APIKey should be the same in the copy")
    XCTAssertEqual(original.version, copy.version, "Version should be the same in the copy")
    XCTAssertEqual(original.connectionType, copy.connectionType, "ConnectionType should be the same in the copy")
    XCTAssertEqual(original.authenticationType, copy.authenticationType, "AuthenticationType should be the same in the copy")
    
    // Additional checks to ensure deep copying if applicable
    if original.customHeaders.count > 0, copy.customHeaders.count > 0 {
      XCTAssertFalse(original.customHeaders === copy.customHeaders, "CustomHeaders should not be the same instance in the copy")
      XCTAssertEqual(original.customHeaders.count, copy.customHeaders.count, "CustomHeaders should have the same count in the copy")
      for (originalHeader, copiedHeader) in zip(original.customHeaders, copy.customHeaders) {
        XCTAssertEqual(originalHeader.header, copiedHeader.header, "Header content should be the same")
      }
    }
  }
  
  private func setupOriginalHostDetails(_ hostDetails: HostDetails) {
    hostDetails.name = "Example Server"
    hostDetails.cloudid = "cloud-12345"
    hostDetails.host = HostURL()
    hostDetails.host?.url = "https://example.com"
    hostDetails.env = "Production"
    hostDetails.username = "user"
    hostDetails.password = "pass"
    hostDetails.authToken = "token123"
    hostDetails.apiToken = "apiToken123"
    hostDetails.apiKey = "apiKey123"
    hostDetails.version = "1.0"
    hostDetails.connectionType = .URL
    hostDetails.authenticationType = .UsernamePassword
    // Assuming a List initializer or similar method to populate custom headers
    let headers = Headers()
    headers.header = "Authorization"
    headers.value = "Bearer xyz"
    hostDetails.customHeaders.append(objectsIn: [headers])
  }
  
  func testGetLocalHeadersEmpty() {
    let hostDetails = HostDetails()
    hostDetails.customHeaders = List<Headers>()  // Ensure it's empty
    
    let localHeaders = hostDetails.getLocalHeaders()
    XCTAssertTrue(localHeaders.isEmpty, "getLocalHeaders should return an empty array when there are no custom headers")
  }
  
  func testGetLocalHeadersMultiple() {
    let hostDetails = HostDetails()
    hostDetails.customHeaders = List<Headers>()
    
    // Create and add header objects
    let header1 = Headers()
    header1.header = "Content-Type"
    header1.value = "application/json"
    let header2 = Headers()
    header2.header = "Accept"
    header2.value = "application/xml"
    hostDetails.customHeaders.append(objectsIn: [header1, header2])
    
    let localHeaders = hostDetails.getLocalHeaders()
    
    XCTAssertEqual(localHeaders.count, 2, "getLocalHeaders should return an array with the same number of elements as the customHeaders list")
    
    // Check data accuracy
    XCTAssertEqual(localHeaders[0].header, "Content-Type", "Header name should match the original")
    XCTAssertEqual(localHeaders[0].value, "application/json", "Header value should match the original")
    XCTAssertEqual(localHeaders[1].header, "Accept", "Header name should match the original")
    XCTAssertEqual(localHeaders[1].value, "application/xml", "Header value should match the original")
  }
  
  
}
