//
//  RNHeadlessManager.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 09/11/22.
//

import Foundation
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

internal class RNHeadlessManagerDelegate: RNFactoryDelegate {

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    override func bundleURL() -> URL? {
        switch Helper.getInfoPlist("HyperswitchSource") {
        case "LocalHosted":
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
        default:
            return Bundle(for: RNHeadlessManager.self).url(forResource: "hyperswitch", withExtension: "bundle")
        }
    }
}

internal class RNHeadlessManager: NSObject, ReactHostManager {

    internal let hyperModule = HyperModuleImpl()
    internal let headlessModule = HyperHeadlessImpl()
    internal var responseHandler: RNResponseHandler?
    internal private(set) var rootView: UIView?

    private let delegate: RNHeadlessManagerDelegate

    internal lazy var factory: RCTReactNativeFactory = {
        RCTReactNativeFactory(delegate: self.delegate)
    }()

    internal static let sharedInstance = RNHeadlessManager()

    internal override init() {
        self.delegate = RNHeadlessManagerDelegate()
        super.init()
        self.delegate.dependencyProvider = RCTAppDependencyProvider()
        self.delegate.manager = self
        self.hyperModule.host = self
    }

    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        let rootView = factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
        self.rootView = rootView
        return rootView
    }

    internal func reinvalidateBridge() {
        self.rootView = nil
        self.factory = RCTReactNativeFactory(delegate: self.delegate)
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
