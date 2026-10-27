//
//  AirborneOTAProvider.swift
//  HyperswitchAirborne
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//
//

import Foundation
import Airborne
import HyperswitchShared

@objc(HyperswitchAirborneOTAProvider)
internal final class AirborneOTAProvider: NSObject, HyperswitchOTAProviding, AirborneDelegate {

    private var services: AirborneServices?
    private let baseBundle: Bundle
    private let bundleName: String
    private let ns: String

    required init(publishableKey: String, baseBundle: Bundle) {
        let configKey = PluginSupport.isSandbox(publishableKey: publishableKey) ? "sandBoxReleaseConfigURL" : "releaseConfigURL"
        let releaseConfigURL = (Self.plist(configKey) ?? "") + "/mobile-ota/ios/" + SDKVersion.current + "/config.json"
        self.baseBundle = baseBundle
        self.bundleName = Self.plist("fileName") ?? "hyperswitch.bundle"
        self.ns = Self.plist("namespace") ?? "hyperswitch"
        super.init()
        self.services = AirborneServices(releaseConfigURL: releaseConfigURL, delegate: self)
    }

    func bundleURL() -> URL? {
        services?.getIndexBundlePath() ?? baseBundle.url(forResource: "hyperswitch", withExtension: "bundle")
    }

    // MARK: - AirborneDelegate

    func namespace() -> String {
        return ns
    }

    func bundle() -> Bundle {
        return baseBundle
    }

    func indexBundleName() -> String {
        return bundleName
    }

    func onEvent(level: String, label: String, key: String, value: [String: Any], category: String, subcategory: String) {
        let eventData: [String: Any] = [
            "label": label,
            "value": JSONSerialization.isValidJSONObject(["key": value]) ? value : String(describing: value),
            "key": key,
            "category": category,
            "subcategory": subcategory,
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: eventData, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            PluginSupport.logOTAEvent(key: key.isEmpty ? label : key, level: level, value: jsonString)
        }
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
