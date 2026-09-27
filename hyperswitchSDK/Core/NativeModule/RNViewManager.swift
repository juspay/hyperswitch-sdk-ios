//
//  RNViewManager.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 01/08/26.
//

import Foundation
import HyperswitchReactNative
import HyperswitchShared
internal import React
internal import ReactAppDependencyProvider
internal import React_RCTAppDelegate
import UIKit

internal protocol ReactHostManager: AnyObject {
    var hyperModule: HyperModuleImpl { get }
    var headlessModule: HyperHeadlessImpl { get }
    var responseHandler: RNResponseHandler? { get set }
    var rootView: UIView? { get }
}

/// Owner of a prefetch surface: receives the JS reply to an updateIntent round trip.
internal protocol UpdateIntentReplyTarget: AnyObject {
    func onUpdateIntentReply(type: String, result: String)
}

internal class RNFactoryDelegate: RCTDefaultReactNativeFactoryDelegate {

    internal weak var manager: ReactHostManager?

    @objc(getModuleInstanceFromClass:)
    internal func getModuleInstanceFromClass(_ moduleClass: AnyClass) -> AnyObject? {
        guard let manager = manager else { return nil }
        if let shimType = moduleClass as? (NSObject & HyperModuleShim).Type {
            let shim = shimType.init()
            manager.hyperModule.attach(to: shim)
            return shim
        }
        if let shimType = moduleClass as? (NSObject & HyperHeadlessShim).Type {
            let shim = shimType.init()
            manager.headlessModule.attach(to: shim)
            return shim
        }
        return nil
    }
}

internal class RNViewManagerDelegate: RNFactoryDelegate {

    /// Over-the-air updates, when the app links the Airborne plugin.
    internal var otaProvider: (any HyperswitchOTAProviding)?

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    override func bundleURL() -> URL? {
        switch Helper.getInfoPlist("HyperswitchSource") {
        case "LocalHosted":
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
        case "LocalBundle":
            return Bundle.main.url(forResource: "hyperswitch", withExtension: "bundle")
        default:
            return otaProvider?.bundleURL()
                ?? Bundle(for: RNViewManager.self).url(forResource: "hyperswitch", withExtension: "bundle")
        }
    }
}

/// The one React host: one JS realm renders every surface of every session and widget.
/// Every surface is one React root on it, told apart by root tag.
internal final class RNViewManager: NSObject, ReactHostManager, SurfaceHost {

    /// Created on first use and kept for the life of the process.
    internal static let shared = RNViewManager()

    internal let hyperModule = HyperModuleImpl()
    internal let headlessModule = HyperHeadlessImpl()
    internal var responseHandler: RNResponseHandler?
    internal private(set) var rootView: UIView?

    private let delegate: RNViewManagerDelegate

    internal lazy var factory: RCTReactNativeFactory = {
        RCTReactNativeFactory(delegate: self.delegate)
    }()

    private override init() {
        self.delegate = RNViewManagerDelegate()
        super.init()
        self.delegate.dependencyProvider = RCTAppDependencyProvider()
        self.delegate.manager = self
        self.hyperModule.host = self
    }

    /// Starts over-the-air updates if the app links the Airborne plugin. Called before
    /// `warmUp` so the host loads the updated bundle; later calls change nothing.
    internal func startOTA(publishableKey: String) {
        guard delegate.otaProvider == nil else { return }
        delegate.otaProvider = OTAProvider.start(publishableKey: publishableKey, baseBundle: Bundle(for: RNViewManager.self))
    }

    /// Boots the host, and with it the bundle, ahead of the first surface so
    /// `initPaymentSession` does not wait for JS evaluation. Idempotent.
    internal func warmUp() {
        DispatchQueue.main.async {
            self.factory.initializeHost()
        }
    }

    /// Creates one React root on the shared host. [owner] is the native object every JS call
    /// carrying this surface's root tag resolves to; it is attached at creation so no surface
    /// can exist without one.
    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?, owner: AnyObject) -> UIView {
        let rootView = factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
        if let surface = rootView.hostedSurface {
            SurfaceOwners.attach(owner, to: surface)
        }
        return rootView
    }

    /// Single-root flows without a session (card field, payment method management,
    /// express checkout): the root created here is the one `exitSheet` dismisses.
    internal func presentedViewForModule(_ moduleName: String, initialProperties: [String: Any]?, owner: AnyObject) -> UIView {
        let rootView = viewForModule(moduleName, initialProperties: initialProperties, owner: owner)
        self.rootView = rootView
        return rootView
    }
}
