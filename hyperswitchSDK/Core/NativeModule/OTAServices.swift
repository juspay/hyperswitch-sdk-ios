//
//  OTAServices.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

#if canImport(Airborne)
import Airborne
import Foundation

private func getHyperOTAPlist(_ key: String) -> String? {
    guard let path = Bundle(for: RNViewManager.self).path(forResource: "HyperOTA", ofType: "plist"),
        let dict = NSDictionary(contentsOfFile: path),
        let value = dict[key] as? String, !value.isEmpty
    else {
        return nil
    }
    return value
}

internal class EventLogger: NSObject, AirborneDelegate {
    private func isJSONSerializable(_ value: Any) -> Bool {
        return JSONSerialization.isValidJSONObject(["key": value])
    }
    internal func addLog(eventData: [String: Any], logLevel: String, key: String?) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: eventData, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("Error: JSON data encoding failed.")
                return
            }
            var log = LogBuilder()
                .setLogType(logLevel)
                .setValue(jsonString)

            switch key {
            case "init_with_local_config_versions":
                log = log.setEventName(.hyperOTAInit)
                break
            case "init":
                log = log.setEventName(.hyperOTAInit)
                break
            case "update_end":
                log = log.setEventName(.hyperOTAFinish)
            case "end":
                log = log.setEventName(.hyperOTAFinish)
                break
            default:
                log = log.setEventName(.hyperOTAEvent)
            }
            LogManager.addLog(log.build())

        } catch {
            print("Error serializing event data: \(error.localizedDescription)")
        }
    }
    func namespace() -> String {
        return getHyperOTAPlist("namespace") ?? "hyperswitch"
    }
    func bundle() -> Bundle {
        return Bundle(for: OTAServices.self)
    }
    func indexBundleName() -> String {
        return getHyperOTAPlist("fileName") ?? "hyperswitch.bundle"
    }
    func onEvent(level: String, label: String, key: String, value: [String: Any], category: String, subcategory: String) {
        let eventData: [String: Any] = [
            "label": label,
            "value": isJSONSerializable(value) ? value : String(describing: value),
            "key": key,
            "category": category,
            "subcategory": subcategory,
        ]
        addLog(eventData: eventData, logLevel: level, key: key)
    }
}

public final class OTAServices {
    public static var shared = OTAServices()
    public var otaServices: AirborneServices? = nil
    let logger = EventLogger()
    public func initialize(publishableKey: String) {
        if self.otaServices == nil {
            let environment = SDKEnvironment.getEnvironment(publishableKey)
            let configKey = (environment == .SANDBOX) ? "sandBoxReleaseConfigURL" : "releaseConfigURL"
            guard let baseURL = getHyperOTAPlist(configKey) else { return }
            self.otaServices = AirborneServices(
                releaseConfigURL: baseURL + "/mobile-ota/ios/" + SDKVersion.current + "/config.json",
                delegate: logger
            )
        }
    }
    public func getBundleURL() -> URL? {
        return otaServices?.getIndexBundlePath() ?? Bundle(for: OTAServices.self).url(forResource: "hyperswitch", withExtension: "bundle")
    }
}
#endif
