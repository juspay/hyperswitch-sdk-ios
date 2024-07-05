//
//  APIClient.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 10/05/23.
//

@objc public class APIClient: NSObject {
    
    @objc(sharedClient) public static let shared: APIClient = {
            let client = APIClient()
            return client
        }()
    
    @objc public var publishableKey: String?
    @objc public var customBackendUrl: String?
    @objc public var customParams: [String : Any]?
    @objc public var customLogUrl: String?
}
