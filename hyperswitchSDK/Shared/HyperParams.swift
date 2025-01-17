//
//  HyperParams.swift
//  hyperswitch
//
//  Created by Shivam Nan on 15/01/25.
//

import Foundation
import WebKit

private let appId = Bundle.main.bundleIdentifier
private let sdkVersion = SDKVersion.current
private let country = NSLocale.current.regionCode
private let ip: String? = nil
private let userAgent = WKWebView().value(forKey: "userAgent")
private let deviceModel = UIDevice.current.model
private let osVersion = UIDevice.current.systemVersion

func getHyperParams(defaultView: Bool? = nil) -> [String: Any?] {
    var hyperParams = [
        "appId" : appId,
        "sdkVersion" : sdkVersion,
        "country" : country,
        "ip": ip,
        "user-agent": userAgent,
        "device_model": deviceModel,
        "os_version": osVersion,
        "os_type": "ios",
        "launchTime": Int(Date().timeIntervalSince1970 * 1000)
    ]
    
    if let defaultView = defaultView {
        hyperParams["defaultView"] = defaultView
    }
    
    return hyperParams
}
