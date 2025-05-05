// SearchOps Source Code
// Core business logic for SearchOps Application
// https://apps.apple.com/app/search-ops/id6453696339
//
// (c) 2025 Ryan McCaffery
// This code is licensed under MIT license (see LICENSE.txt for details)
// ---------------------------------------

import Foundation

class InsecureConnection {
    static func session() -> URLSession {
        return URLSession(configuration: .default, 
                          delegate: AllowInsecureConnectionDelegate(),
                          delegateQueue: nil)
    }
}

class AllowInsecureConnectionDelegate: NSObject, URLSessionDelegate {
  func urlSession(_ session: URLSession,
                  didReceive challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
    completionHandler(.useCredential, credential)
  }
}
