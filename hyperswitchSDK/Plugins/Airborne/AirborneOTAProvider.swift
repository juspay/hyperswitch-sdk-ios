//
//  AirborneOTAProvider.swift
//  HyperswitchAirborne
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//
//

import Foundation
internal import HyperOTA
import HyperswitchShared

@objc(HyperswitchAirborneOTAProvider)
internal final class AirborneOTAProvider: NSObject, HyperswitchOTAProviding {

    private let services: HyperOTAServices
    private let baseBundle: Bundle
    private let logger = EventLogger()

    required init(publishableKey: String, baseBundle: Bundle) {
        let configKey = PluginSupport.isSandbox(publishableKey: publishableKey) ? "sandBoxReleaseConfigURL" : "releaseConfigURL"
        let payload =
            [
                "clientId": Self.plist("clientId") ?? "",
                "namespace": Self.plist("namespace") ?? "",
                "forceUpdate": true,
                "localAssets": (Self.plist(configKey) ?? "releaseConfigURL") == "releaseConfigURL",
                "fileName": Self.plist("fileName") ?? "",
                "releaseConfigURL": (Self.plist(configKey) ?? "") + "/mobile-ota/ios/" + SDKVersion.current + "/config.json",
            ] as [String: Any]
        self.baseBundle = baseBundle
        self.services = HyperOTAServices(payload: payload, loggerDelegate: logger, baseBundle: baseBundle)
        super.init()
    }

    func bundleURL() -> URL? {
        services.bundleURL() ?? baseBundle.url(forResource: "hyperswitch", withExtension: "bundle")
    }

    /// A value of this plugin's HyperOTA.plist.
    private static func plist(_ key: String) -> String? {
        guard let path = Bundle(for: AirborneOTAProvider.self).path(forResource: "HyperOTA", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let value = dict[key] as? String, !value.isEmpty
        else {
            return nil
        }
        return value
    }
}

/// Forwards HyperOTA's events to the SDK's native log.
internal final class EventLogger: NSObject, HPJPLoggerDelegate {
    private func isJSONSerializable(_ value: Any) -> Bool {
        return JSONSerialization.isValidJSONObject(["key": value])
    }

    private func addLog(eventData: [String: Any], logLevel: String, key: String?) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: eventData, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            print("Error: JSON data encoding failed.")
            return
        }
        PluginSupport.logOTAEvent(key: key, level: logLevel, value: jsonString)
    }

    func trackEvent(
        withLevel logLevel: String,
        label eventLabel: String,
        key eventKey: String? = nil,
        value eventValue: Any,
        category eventCategory: String,
        subcategory eventSubcategory: String
    ) {
        let eventData: [String: Any] = [
            "label": eventLabel,
            "value": isJSONSerializable(eventValue) ? eventValue : String(describing: eventValue),
            "key": eventKey ?? "",
            "category": eventCategory,
            "subcategory": eventSubcategory,
        ]
        addLog(eventData: eventData, logLevel: logLevel, key: eventKey)
    }

    func trackEvent(
        withLevel logLevel: String,
        label eventLabel: String,
        value eventValue: Any,
        category eventCategory: String,
        subcategory eventSubcategory: String
    ) {
        let eventData: [String: Any] = [
            "label": eventLabel,
            "value": isJSONSerializable(eventValue) ? eventValue : String(describing: eventValue),
            "category": eventCategory,
            "subcategory": eventSubcategory,
        ]
        addLog(eventData: eventData, logLevel: logLevel, key: eventLabel)
    }
}
