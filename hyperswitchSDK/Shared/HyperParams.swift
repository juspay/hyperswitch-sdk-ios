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
    static let userAgent: String? = WKWebView().value(forKey: "userAgent") as? String
    static let deviceModel: String = UIDevice.current.model
    static let osVersion: String = UIDevice.current.systemVersion
    
    static func getSafeAreaInsets() -> UIEdgeInsets {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets ?? UIEdgeInsets.zero
    }
    
    static func getHyperParams() -> [String: Any?] {
        
        let safeAreaInset = getSafeAreaInsets()
        
        let params: [String: Any?] = [
            "appId": appId,
            "sdkVersion": sdkVersion,
            "country": country,
            "user-agent": userAgent,
            "device_model": deviceModel,
            "os_version": osVersion,
            "os_type": "ios",
            "launchTime": Int(Date().timeIntervalSince1970 * 1000),
            "topInset": safeAreaInset.top,
            "bottomInset":safeAreaInset.bottom,
            "leftInset":safeAreaInset.left,
            "rightInset":safeAreaInset.right,
        ]
        return params
    }
}
