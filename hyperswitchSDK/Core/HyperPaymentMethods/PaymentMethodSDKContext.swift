//
//  PaymentMethodSDKContext.swift
//  hyperswitch payment-method session SDK
//
//  Host/device context helpers local to the payment-method session SDK — its own
//  copies, so the SDK builds as a standalone library without reaching into the
//  main SDK's internals. Mirrors `Helper.getInfoPlist` / `SDKParams.getSDKParams`.
//

import Foundation
import UIKit
import WebKit
#if canImport(Hyperswitch)
import Hyperswitch  // main SDK's public `SDKVersion`, when built as a separate pod
#endif

internal enum PMContext {

    /// App `Info.plist` string value (bundle-source switch used for JS bundle resolution).
    internal static func infoPlist(_ key: String) -> String? {
        guard let infoDictionary = Bundle.main.infoDictionary,
            let value = infoDictionary[key] as? String, !value.isEmpty
        else {
            return nil
        }
        return value
    }

    /// Device/SDK params forwarded to every RN surface of a payment-method session
    /// (same payload shape as the main SDK's `SDKParams.getSDKParams()`).
    internal static func sdkParams() -> [String: Any?] {
        let insets = safeAreaInsets()

        let params: [String: Any?] = [
            "appId": Bundle.main.bundleIdentifier,
            "sdkVersion": SDKVersion.current,
            "country": NSLocale.current.regionCode,
            "user-agent": currentUserAgent(),
            "device_model": UIDevice.current.model,
            "os_version": UIDevice.current.systemVersion,
            "os_type": "ios",
            "launchTime": Int(Date().timeIntervalSince1970 * 1000),
            "topInset": Float(insets.top),
            "bottomInset": Float(insets.bottom),
            "leftInset": Float(insets.left),
            "rightInset": Float(insets.right),
        ]
        return params
    }

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
    private static func safeAreaInsets() -> UIEdgeInsets {
        guard Thread.isMainThread else { return .zero }
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first
        return window?.safeAreaInsets ?? .zero
    }
}
