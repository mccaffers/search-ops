// SearchOps Swift Package
// Business logic for SearchOps iOS Application
//
// (c) 2024 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

@available(macOS 13.0, *)
@available(iOS 13.0.0, *)
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

@available(macOS 13.0, *)
extension URLSession: URLSessionProtocol {}

// Request Class
// Builds URLSessions, with Search Credentials
@available(macOS 13.0, *)
@available(iOS 16.0.0, *)
class Request {
  
  // Entry Point for a Mock Session
  // Simple way to inject a new session for testing
  static var mockedSession : URLSessionProtocol?
  
  private var localSession : URLSessionProtocol
  
  @MainActor
  public init() {
    if let mock = Request.mockedSession {
      self.localSession = mock
    } else {
      let sessionConfig = URLSessionConfiguration.default
      let settingsManager = SettingsDatatManager()
      sessionConfig.timeoutIntervalForRequest =  TimeInterval(settingsManager.settings?.requestTimeout ?? Int(Constants.DEFAULT_REQUEST_TIMEOUT))
      sessionConfig.timeoutIntervalForResource =  TimeInterval(settingsManager.settings?.requestTimeout ?? Int(Constants.DEFAULT_REQUEST_TIMEOUT))
      self.localSession = URLSession(configuration: .default)
    }
    
  }
  
  @MainActor
  func buildUrl(_ serverDetails: HostDetails, _ endpoint: String) -> String {
    var urlBuilder = "";
    
    // If Cloud ID has been defined try to unwrap to get host, port and any endpoints
    if serverDetails.cloudid.count > 0 {
      
      let LogHostDetails = AuthBuilder.ConvertCloudIDIntoHost(cloudID: serverDetails.cloudid)
      urlBuilder = LogHostDetails.0 + ":" + LogHostDetails.1 + endpoint;
      
    } else if let host = serverDetails.host {
     
      if host.scheme == .HTTPS {
        urlBuilder = "https://"
      } else {
        urlBuilder = "http://"
      }
      
      // Remove any whitespace from the string
      // Check the port is an integer
      let port = Int(host.port.trimmingCharacters(in: .whitespacesAndNewlines))
      
      // Check the port is valid and more than 0
      if let port = port, port > 0 {
        urlBuilder = urlBuilder + host.url + ":" + String(port) + endpoint;
      } else {
        urlBuilder = urlBuilder + host.url + endpoint;
      }
      
    }
    
    return urlBuilder
  }
  
  private func buildRequest(url: URL,
                    method: String,
                    authorisationString: String,
                    additionalHeader: [String:String] ) -> URLRequest {
    
    var request = URLRequest(
      url: url,
      cachePolicy: .reloadIgnoringLocalCacheData
    )
    
    request.httpMethod = method
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    if !authorisationString.isEmpty {
      request.addValue(authorisationString, forHTTPHeaderField: "Authorization")
    }
    
    for headers in additionalHeader {
      request.addValue(headers.key, forHTTPHeaderField: headers.value)
    }
    
    return request
  }
  
  
  @MainActor
  func invoke(serverDetails: HostDetails,
              endpoint: String,
              json : String? = nil) async -> ServerResponse {
    
    var request: URLRequest;
    
    if let host = serverDetails.host, host.selfSignedCertificate {
      self.localSession = InsecureConnection.session()
    }
    
    let settingsManager = SettingsDatatManager()
    
    let resObject = ServerResponse()
    
    resObject.method = "GET" // default
    if json != nil {
      resObject.method = "POST"
    }
    
    do {
      
      let urlBuilder = buildUrl(serverDetails, endpoint)
      
      if let url = URL(string: urlBuilder) {
        
        resObject.url = url
        
        request = URLRequest(
          url: url,
          cachePolicy: .reloadIgnoringLocalCacheData,
          timeoutInterval: TimeInterval(settingsManager.settings?.requestTimeout ?? Int(Constants.DEFAULT_REQUEST_TIMEOUT))
        )
        
        var authorisationString : String = ""
        var additionalHeaders : [String:String] =  [:]
        
        if !serverDetails.authToken.isEmpty {
          authorisationString = "Basic " + serverDetails.authToken
        }
        else if !serverDetails.username.isEmpty {
          authorisationString = "Basic " + AuthBuilder.MakeBearer(username: serverDetails.username,
                                                                  password: serverDetails.password)
        } else if !serverDetails.apiToken.isEmpty {
          authorisationString = "Bearer " + serverDetails.apiToken
        } else if !serverDetails.apiKey.isEmpty {
          authorisationString = "ApiKey " + serverDetails.apiKey
          additionalHeaders = ["kbn-xsrf": "true"]
        }
        
        if serverDetails.customHeaders.count > 0 {
          for header in serverDetails.customHeaders {
            additionalHeaders[header.header] = header.value
          }
        }
        request = buildRequest(url: url,
                               method: resObject.method ?? "GET",
                               authorisationString: authorisationString,
                               additionalHeader: additionalHeaders)
        
        if let jsonData = json?.data {
          request.httpBody = jsonData // try json.rawData()
        }
        
        let response = try await localSession.data(for: request)
        
        resObject.data = response.0
        resObject.response = response.1
        
        if let httpResponse = response.1 as? HTTPURLResponse {
          resObject.httpStatus = httpResponse.statusCode
        }
        
        
      } else {
        let myError = ResponseError(title: "Request Error",
                                    message: "Invalid URL",
                                    type: .critical)
        resObject.error = myError
      }
      
    }
    catch let error {
      
      var errorMessage = error.localizedDescription
      if errorMessage.contains("timeout") {
        errorMessage = "Request timed out"
      }
      
      let myError = ResponseError(title: "Request Error",
                                  message: errorMessage,
                                  type:.critical)
      //			let resObject = ServerResponse(error:myError)
      
      
      resObject.error = myError
      //            return nil
    }
    
    return resObject
  }
  
}


