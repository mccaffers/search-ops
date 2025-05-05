// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import XCTest

@testable import Search_Ops

final class UtilityTests: XCTestCase {
    
    let emptyResponse = ("", "")
    
    // Blank input
    func testBlankConvertCloudIDIntoHost() throws {
        let input = ""
        let output = AuthBuilder.ConvertCloudIDIntoHost(cloudID: input)
        
        XCTAssertEqual(output.0, emptyResponse.0)
        XCTAssertEqual(output.1, emptyResponse.1)
    }
    
    // Empty input with single colon
    func testEmptyConvertCloudIDIntoHost() throws {
        let input = ":"
        let output = AuthBuilder.ConvertCloudIDIntoHost(cloudID: input)
        
        XCTAssertEqual(output.0, emptyResponse.0)
        XCTAssertEqual(output.1, emptyResponse.1)
    }

    // Missing both $ sign
    func testConvertCloudIDMissingDollar() throws {
        
        // echo 'europe-west2.gcp.elastic-cloud.com:443' | base64
        // ZXVyb3BlLXdlc3QyLmdjcC5lbGFzdGljLWNsb3VkLmNvbTo0NDMK
        
        let input = "My_deployment:ZXVyb3BlLXdlc3QyLmdjcC5lbGFzdGljLWNsb3VkLmNvbTo0NDMK"
        let output = AuthBuilder.ConvertCloudIDIntoHost(cloudID: input)
        
        XCTAssertEqual(output.0, emptyResponse.0)
        XCTAssertEqual(output.1, emptyResponse.1)
    }
    
    // Invalid port
    func testConvertCloudIDCustomPort() throws {
        
        // echo 'europe-west2.gcp.elastic-cloud.com:5000$$' | base64
        // ZXVyb3BlLXdlc3QyLmdjcC5lbGFzdGljLWNsb3VkLmNvbTo1MDAwJCQK
        
        let input = "My_deployment:ZXVyb3BlLXdlc3QyLmdjcC5lbGFzdGljLWNsb3VkLmNvbTo1MDAwJCQK"
        let output = AuthBuilder.ConvertCloudIDIntoHost(cloudID: input)
        
        let expected = ("https://europe-west2.gcp.elastic-cloud.com", "5000")
        
        XCTAssertEqual(output.0, expected.0)
        XCTAssertEqual(output.1, expected.1)
    }
    
    
    // Invalid port
    func testConvertCloudIDInvalidPort() throws {
        
        // echo 'europe-west2.gcp.elastic-cloud.com:-23$$' | base64
        // ZXVyb3BlLXdlc3QyLmdjcC5lbGFzdGljLWNsb3VkLmNvbTotMjMkJAo=
        
        let input = "My_deployment:ZXVyb3BlLXdlc3QyLmdjcC5lbGFzdGljLWNsb3VkLmNvbTotMjMkJAo="
        let output = AuthBuilder.ConvertCloudIDIntoHost(cloudID: input)
        
        let expected = ("https://europe-west2.gcp.elastic-cloud.com", "443")
        
        XCTAssertEqual(output.0, expected.0)
        XCTAssertEqual(output.1, expected.1)
    }
    
    
    // No values between the $ signs
    func testConvertCloudIDEmptyDollarInput() throws {
        
        // echo 'europe-west2.gcp.elastic-cloud.com:443$$' | base64
        // ZXVyb3BlLXdlc3QyLmdjcC5lbGFzdGljLWNsb3VkLmNvbTo0NDMkJAo=
        
        let input = "My_deployment:ZXVyb3BlLXdlc3QyLmdjcC5lbGFzdGljLWNsb3VkLmNvbTo0NDMkJAo="
        let output = AuthBuilder.ConvertCloudIDIntoHost(cloudID: input)
        
        // No subdomain with missing dollars
        let expected = ("https://europe-west2.gcp.elastic-cloud.com", "443")
        
        XCTAssertEqual(output.0, expected.0)
        XCTAssertEqual(output.1, expected.1)
    }
    
    
    // Full representation of a Cloud ID
    func testFullConvertCloudIDIntoHost() throws {
        
        // echo 'europe-west2.gcp.elastic-cloud.com:443$abcdef1234$abcdef1234' | base64
        // ZXVyb3BlLXdlc3QyLmdjcC5lbGFzdGljLWNsb3VkLmNvbTo0NDMkYWJjZGVmMTIzNCRhYmNkZWYxMjM0Cg==
        
        let input = "My_deployment:ZXVyb3BlLXdlc3QyLmdjcC5lbGFzdGljLWNsb3VkLmNvbTo0NDMkYWJjZGVmMTIzNCRhYmNkZWYxMjM0Cg=="
        let output = AuthBuilder.ConvertCloudIDIntoHost(cloudID: input)
        let expected = ("https://abcdef1234.europe-west2.gcp.elastic-cloud.com", "443")
        XCTAssertEqual(output.0, expected.0)
        XCTAssertEqual(output.1, expected.1)
    }

}
