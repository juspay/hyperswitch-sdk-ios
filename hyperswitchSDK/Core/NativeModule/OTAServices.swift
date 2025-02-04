//
//  OTAServices.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation
import HyperOTA

internal class EventLogger: NSObject, HPJPLoggerDelegate {
    private func isJSONSerializable(_ value: Any) -> Bool {
        return JSONSerialization.isValidJSONObject(["key": value])
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
            HyperLogManager.addLog(log.build())
            
        } catch {
            print("Error serializing event data: \(error.localizedDescription)")
        }
    }
    
    
}

public final class OTAServices {
    public func getBundleURL() -> URL {
        let payload = [
            "clientId": "hyperswitch",
            "namespace": "hyperswitch",
            "forceUpdate": true,
            "localAssets": false,
            "fileName": "hyperswitch.bundle",
            "releaseConfigURL": "http://localhost:3000/files/hyperswitch/ios/release-config.json",
        ] as [String: Any]
        let logger = EventLogger()
        return HyperOTAServices.bundleURL(payload, loggerDelegate: logger)
    }
}
