//
//  OTAServices.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation
import HyperOTA

class MyLogger: NSObject, HPJPLoggerDelegate {
    func trackEvent(
        withLevel level: String,
        label: String,
        value: Any,
        category: String,
        subcategory: String
    ) {
        print("Tracking event: \(label) [\(level)]" , value)
    }
}

public final class OTAServices {
    public static func getBundleURL() -> URL? {
        let payload = [
            "clientId": "hyperswitch",
            "namespace": "hyperswitch", // Default is juspay.
            "forceUpdate": true,
            "localAssets": false, // To use assets from the app's bundle. Default is false.
            "fileName": "hyperswitch.bundle", // Index file name. Default is 'main.jsbundle'.
            "releaseConfigURL": "http://10.10.68.233:3000/files/hyperswitch/ios/release-config.json", // demo ServerURL
        ] as [String: Any]
        let logger = MyLogger()
        
        do {
            let bundleURL = try HyperOTAServices.bundleURL(payload, loggerDelegate: logger)
            return bundleURL
        } catch {
            return Bundle.main.url(forResource: "hyperswitch", withExtension: "bundle")
        }
    }
}
