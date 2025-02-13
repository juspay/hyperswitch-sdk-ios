//
//  HyperParams.swift
//  hyperswitch
//
//  Created by Shivam Nan on 15/01/25.
//

import Foundation
import WebKit

class HyperParams {
    static let appId: String? = Bundle.main.bundleIdentifier
    static let sdkVersion: String = SDKVersion.current
    static let country: String? = NSLocale.current.regionCode
    static let ip: String? = nil
    static let userAgent: String? = WKWebView().value(forKey: "userAgent") as? String
    static let deviceModel: String = UIDevice.current.model
    static let osVersion: String = UIDevice.current.systemVersion
    
    static func getHyperParams() -> [String: Any?] {
        var params: [String: Any?] = [
            "appId": appId,
            "sdkVersion": sdkVersion,
            "country": country,
            "ip": ip,
            "user-agent": userAgent,
            "device_model": deviceModel,
            "os_version": osVersion,
            "os_type": "ios",
            "launchTime": Int(Date().timeIntervalSince1970 * 1000)
        ]
        
        return params
    }
}
