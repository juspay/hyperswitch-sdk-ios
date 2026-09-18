//
//  SDKParams.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 17/06/26.
//

import UIKit
import WebKit

class SDKParams {
    static let appId: String? = Bundle.main.bundleIdentifier
    static let sdkVersion: String = SDKVersion.current
    static let country: String? = NSLocale.current.regionCode
    static let deviceModel: String = UIDevice.current.model
    static let osVersion: String = UIDevice.current.systemVersion

    /// The web-view user agent, read once. Creating a `WKWebView` must happen on the main
    /// thread, so the first read off the main thread yields nil (the RN side tolerates a
    /// missing value) and the value is filled in by the first read on it.
    private static var cachedUserAgent: String?

    private static func currentUserAgent() -> String? {
        if let cachedUserAgent { return cachedUserAgent }
        guard Thread.isMainThread else { return nil }
        let userAgent = WKWebView().value(forKey: "userAgent") as? String
        cachedUserAgent = userAgent
        return userAgent
    }

    /// Safe-area insets of the key window (zero off the main thread / when unavailable).
    private static func safeAreaInsets() -> UIEdgeInsets {  // FIXME: replace with <SafeAreaView>.
        guard Thread.isMainThread else { return .zero }  // MARK: bailout since RN can handle.
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first
        return window?.safeAreaInsets ?? .zero
    }

    static func getSDKParams() -> [String: Any?] {

        let insets = safeAreaInsets()

        let params: [String: Any?] = [
            "appId": appId,
            "sdkVersion": sdkVersion,
            "country": country,
            "user-agent": currentUserAgent(),
            "device_model": deviceModel,
            "os_version": osVersion,
            "os_type": "ios",
            "launchTime": Int(Date().timeIntervalSince1970 * 1000),
            "topInset": Float(insets.top),
            "bottomInset": Float(insets.bottom),
            "leftInset": Float(insets.left),
            "rightInset": Float(insets.right),
        ]
        return params
    }
}
