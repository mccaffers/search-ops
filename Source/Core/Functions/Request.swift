// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
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
      let settingsManager = SettingsDataManager()
      sessionConfig.timeoutIntervalForRequest =  TimeInterval(settingsManager.settings?.requestTimeout ?? Int(Constants.defaultRequestTimeout))
      sessionConfig.timeoutIntervalForResource =  TimeInterval(settingsManager.settings?.requestTimeout ?? Int(Constants.defaultRequestTimeout))
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
  
  @MainActor
  private func buildRequest(url: URL,
                    method: String,
                    authorisationString: String,
                    additionalHeader: [String:String],
                    timeoutInterval: TimeInterval? = nil) -> URLRequest {
    
    var request = URLRequest(
      url: url,
      cachePolicy: .reloadIgnoringLocalCacheData
    )
    let settingsManager = SettingsDataManager()
    request.timeoutInterval = timeoutInterval ?? TimeInterval(settingsManager.settings?.requestTimeout ?? Int(Constants.defaultRequestTimeout))
    
    request.httpMethod = method
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    if !authorisationString.isEmpty {
      request.addValue(authorisationString, forHTTPHeaderField: "Authorization")
    }
    
    for headers in additionalHeader {
      request.addValue(headers.value, forHTTPHeaderField: headers.key)
    }
    
    return request
  }
  
  
  @MainActor
  func invoke(serverDetails: HostDetails,
              endpoint: String,
              json : String? = nil,
              method: String? = nil,
              timeoutInterval: TimeInterval? = nil) async -> ServerResponse {
    
    var request: URLRequest;
    
    if let host = serverDetails.host, host.selfSignedCertificate {
      self.localSession = InsecureConnection.session()
    }
    
    let resObject = ServerResponse()
    
    // Explicit method takes precedence over the body-based default
    resObject.method = method ?? (json != nil ? "POST" : "GET")
    
    do {
      
      let urlBuilder = buildUrl(serverDetails, endpoint)
      
      if let url = URL(string: urlBuilder) {
        
        resObject.url = url
        
        let authorisation = Request.authorisation(for: serverDetails)
        var additionalHeaders = authorisation.headers
        
        for header in serverDetails.customHeaders {
          if serverDetails.authenticationType == .AWSSigV4,
             Request.isReservedForSigV4(header: header.header) {
            continue
          }
          additionalHeaders[header.header] = header.value
        }
        
        request = buildRequest(url: url,
                               method: resObject.method ?? "GET",
                               authorisationString: authorisation.value,
                               additionalHeader: additionalHeaders,
                               timeoutInterval: timeoutInterval)
        
        if let jsonData = json?.data {
          request.httpBody = jsonData // try json.rawData()
        }
        
        // Sign last, so every retry is signed with the current time
        let signer = Request.signer(for: serverDetails)
        if let signer = signer {
          request = signer.sign(request)
        }
        
        let response = try await localSession.data(for: request)
        
        resObject.data = response.0
        resObject.response = response.1
        
        if let httpResponse = response.1 as? HTTPURLResponse {
          resObject.httpStatus = httpResponse.statusCode
        }
        
        if let signer = signer {
          Request.handleSigV4Response(resObject, sessionToken: signer.credentials.sessionToken)
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
      
      resObject.error = myError
    }
    
    return resObject
  }
  
  
  // The static Authorization header, picked by authentication type.
  // SigV4 has none, its header is computed per request by the signer.
  // Hosts left on None keep the old behaviour of using whichever field is filled in.
  static func authorisation(for serverDetails: HostDetails) -> (value: String, headers: [String:String]) {
    switch serverDetails.authenticationType {
    case .AWSSigV4:
      return ("", [:])
    case .AuthToken:
      return (serverDetails.authToken.isEmpty ? "" : "Basic " + serverDetails.authToken, [:])
    case .UsernamePassword:
      return (serverDetails.username.isEmpty ? "" : "Basic " + AuthBuilder.MakeBearer(username: serverDetails.username,
                                                                                         password: serverDetails.password), [:])
    case .APIToken:
      return (serverDetails.apiToken.isEmpty ? "" : "Bearer " + serverDetails.apiToken, [:])
    case .APIKey:
      return (serverDetails.apiKey.isEmpty ? "" : "ApiKey " + serverDetails.apiKey,
              serverDetails.apiKey.isEmpty ? [:] : ["kbn-xsrf": "true"])
    case .None:
      if !serverDetails.authToken.isEmpty {
        return ("Basic " + serverDetails.authToken, [:])
      } else if !serverDetails.username.isEmpty {
        return ("Basic " + AuthBuilder.MakeBearer(username: serverDetails.username,
                                                  password: serverDetails.password), [:])
      } else if !serverDetails.apiToken.isEmpty {
        return ("Bearer " + serverDetails.apiToken, [:])
      } else if !serverDetails.apiKey.isEmpty {
        return ("ApiKey " + serverDetails.apiKey, ["kbn-xsrf": "true"])
      }
      return ("", [:])
    }
  }
  
  // Custom headers that would collide with the signed ones. addValue appends
  // to an existing header, which breaks the signature, so they aren't sent.
  static func isReservedForSigV4(header: String) -> Bool {
    let name = header.trimmingCharacters(in: .whitespaces).lowercased()
    return name == "authorization" || name == "host" || name == "content-type" || name.hasPrefix("x-amz-")
  }
  
  // A signer for SigV4 hosts. The region falls back to the one in the endpoint hostname.
  static func signer(for serverDetails: HostDetails) -> AWSSigV4Signer? {
    guard serverDetails.authenticationType == .AWSSigV4 else {
      return nil
    }
    
    let token = serverDetails.awsSessionToken.trimmingCharacters(in: .whitespacesAndNewlines)
    var region = serverDetails.awsRegion.trimmingCharacters(in: .whitespacesAndNewlines)
    if region.isEmpty, let detected = AWSEndpoint.detect(serverDetails.host?.url ?? "") {
      region = detected.region
    }
    
    let credentials = AWSCredentials(
      accessKeyId: serverDetails.awsAccessKeyId.trimmingCharacters(in: .whitespacesAndNewlines),
      secretAccessKey: serverDetails.awsSecretAccessKey.trimmingCharacters(in: .whitespacesAndNewlines),
      sessionToken: token.isEmpty ? nil : token)
    
    return AWSSigV4Signer(credentials: credentials,
                          region: region,
                          service: serverDetails.awsService.rawValue)
  }
  
  // Runs once for every SigV4 response, before any caller parses or logs the body
  static func handleSigV4Response(_ resObject: ServerResponse, sessionToken: String?) {
    guard let data = resObject.data else {
      return
    }
    
    let redacted = AWSSigV4Response.redact(data, sessionToken: sessionToken)
    resObject.data = redacted
    
    guard resObject.httpStatus == 403,
          let body = String(data: redacted, encoding: .utf8),
          let message = AWSSigV4Response.errorMessage(for: body) else {
      return
    }
    
    resObject.error = ResponseError(title: "AWS Authentication Error",
                                    message: message,
                                    type: .critical)
    
    // Don't show the canonical string the server echoes back on a mismatch
    if body.contains("The request signature we calculated does not match"),
       let replacement = try? JSONSerialization.data(withJSONObject: ["message": message]) {
      resObject.data = replacement
    }
  }

}


