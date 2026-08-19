//
//  RNHeadlessManager.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 09/11/22.
//

import Foundation
import React

internal class RNHeadlessManager: NSObject {

    internal var responseHandler: RNResponseHandler?
    internal var rootView: RCTRootView?

    internal lazy var bridgeHeadless: RCTBridge = {
        RCTBridge.init(delegate: self, launchOptions: nil)
    }()

    internal static let sharedInstance = RNHeadlessManager()

    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> RCTRootView {
        let rootView: RCTRootView = RCTRootView(
            bridge: self.bridgeHeadless,
            moduleName: moduleName,
            initialProperties: initialProperties
        )
        self.rootView = rootView
        return rootView
    }

    /// Unmounts one completed headless root without destroying the bridge or its JS module cache.
    internal func releaseRootView(_ completedRootView: RCTRootView) {
        guard rootView === completedRootView else { return }
        rootView = nil
    }

    internal func removePrefetchCache(sdkAuthorization: String) {
        guard !sdkAuthorization.isEmpty else { return }
        bridgeHeadless.enqueueJSCall(
            "RCTDeviceEventEmitter",
            method: "emit",
            args: [
                "clearPrefetchCache",
                ["sdkAuthorization": sdkAuthorization],
            ],
            completion: nil
        )
    }

}

extension RNHeadlessManager: RCTBridgeDelegate {
    func sourceURL(for bridge: RCTBridge) -> URL? {
        switch Helper.getInfoPlist("HyperswitchSource") {
        case "LocalHosted":
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
        default:
            return Bundle(for: RNHeadlessManager.self).url(forResource: "hyperswitch", withExtension: "bundle")
        }
    }
}
