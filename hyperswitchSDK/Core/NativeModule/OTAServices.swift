//
//  OTAServices.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation
import HyperOTA

private func getHyperOTAPlist(_ key: String) -> String? {
    guard let path = Bundle(for: RNViewManager.self).path(forResource: "HyperOTA", ofType: "plist"),
          let dict = NSDictionary(contentsOfFile: path),
          let value = dict[key] as? String, !value.isEmpty else {
        return nil
    }
    return value
}

internal class EventLogger: NSObject, HPJPLoggerDelegate {
    private func isJSONSerializable(_ value: Any) -> Bool {
        return JSONSerialization.isValidJSONObject(["key": value])
    }
    internal func addLog(eventData: [String: Any], logLevel : String, eventLabel: String){
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: eventData, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("Error: JSON data encoding failed.")
                return
            }
            var log = LogBuilder()
                .setLogType(logLevel)
                .setValue(jsonString)
            
            switch eventLabel {
            case "init":
                log = log.setEventName(.HYPER_OTA_INIT)
            case "end":
                log = log.setEventName(.HYPER_OTA_FINISH)
            default:
                log = log.setEventName(.HYPER_OTA_EVENT)
            }
            LogManager.addLog(log.build())
            
        } catch {
            print("Error serializing event data: \(error.localizedDescription)")
        }
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
            "key" : eventKey ?? "",
            "category": eventCategory,
            "subcategory": eventSubcategory
        ]
        addLog(eventData: eventData, logLevel: logLevel, eventLabel:eventLabel)
        
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
            "subcategory": eventSubcategory
        ]
        addLog(eventData: eventData, logLevel: logLevel, eventLabel:eventLabel)
        
    }
}

public final class OTAServices {
    public static var shared = OTAServices()
    public var otaServices : HyperOTAServices? = nil
    public func initialize(publishableKey : String) {
        if(self.otaServices == nil) {
            let environment = SDKEnvironment.getEnvironment(publishableKey)
            let configKey = (environment == .SANDBOX) ? "sandBoxReleaseConfigURL" : "releaseConfigURL" 
            let payload = [
                "clientId": getHyperOTAPlist("clientId") ?? "" ,
                "namespace": getHyperOTAPlist("namespace") ?? "",
                "forceUpdate": true,
                "localAssets": (getHyperOTAPlist(configKey) ?? "releaseConfigURL") == "releaseConfigURL",
                "fileName": getHyperOTAPlist("fileName") ?? "" ,
                "releaseConfigURL": (getHyperOTAPlist(configKey) ?? "") +  "/mobile-ota/ios/" + SDKVersion.current + "/config.json",
            ] as [String: Any]
            let logger = EventLogger()
            self.otaServices = HyperOTAServices(payload: payload, loggerDelegate: logger, baseBundle: Bundle(for: OTAServices.self))
        }
    }
    public  func getBundleURL() -> URL? {
        return otaServices?.bundleURL() ?? Bundle(for: OTAServices.self).url(forResource: "hyperswitch", withExtension: "bundle")
    }
}
