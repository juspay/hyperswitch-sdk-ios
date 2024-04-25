//
//  APIClient.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 14/07/23.
//

import Foundation
import UIKit

@objc public class APIClient: NSObject {
    
    @objc(sharedClient) public static let shared: APIClient = {
        let client = APIClient()
        return client
    }()
    
    @objc public var publishableKey: String? {
        get {
            if let publishableKey = _publishableKey {
                return publishableKey
            }
            return HyperAPI.defaultPublishableKey
        }
        set {
            _publishableKey = newValue
        }
    }
    var _publishableKey: String?
    
    @objc public var customBackendUrl: String? {
        get {
            if let customBackendUrl = _customBackendUrl {
                return customBackendUrl
            }
            return HyperAPI.customBackendUrl
        }
        set {
            _customBackendUrl = newValue
        }
    }
    var _customBackendUrl: String?
    
    
    @objc public var customParams: [String : Any]? {
        get {
            if let customParams = _customParams {
                return customParams
            }
            return HyperAPI.customParams
        }
        set {
            _customParams = newValue
        }
    }
    var _customParams: [String : Any]?
    
    @objc public var customLogUrl: String? {
        get {
            if let customLogUrl = _customLogUrl {
                return customLogUrl
            }
            return HyperAPI.customLogUrl
        }
        set {
            _customLogUrl = newValue
        }
    }
    var _customLogUrl: String?

}
