//
//  HyperOTA.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 22/01/25.
//

import HyperOTA

var bundleURL: URL {
    let payload = [
        "clientId": "hyperswitch",
        "namespace": "hyperswitch", // Default is juspay.
        "forceUpdate": true,
        "localAssets": false, // To use assets from the app's bundle. Default is false.
        "fileName": "hyperswitch.bundle", // Index file name. Default is 'main.jsbundle'.
        "releaseConfigURL": "http://10.10.68.233:3000/files/hyperswitch/ios/release-config.json"
    ] as [String: Any]

    let url = HyperOTAServices.bundleURL(payload)
    print(url)
    return url
}
