//
//  RNViewManager.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 01/08/26.
//

import Foundation
import React
import ReactAppDependencyProvider
import React_RCTAppDelegate

internal protocol ReactHostManager: AnyObject {
    var hyperModule: HyperModuleImpl { get }
    var headlessModule: HyperHeadlessImpl { get }
    var responseHandler: RNResponseHandler? { get set }
    var rootView: UIView? { get }
}

extension UIView {
    internal var surfaceRootTag: NSNumber? {
        guard let rootView = self as? RCTSurfaceHostingProxyRootView else { return nil }
        return NSNumber(value: rootView.surface.rootTag)
    }

    internal func nearestAncestor(where predicate: (UIView) -> Bool) -> UIView? {
        var current: UIView? = self
        while let view = current {
            if predicate(view) {
                return view
            }
            current = view.superview
        }
        return nil
    }

    internal func nearestAncestor<T>(ofType type: T.Type) -> T? {
        return nearestAncestor(where: { $0 is T }) as? T
    }
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
        if let shimType = moduleClass as? (NSObject & PaymentMethodModuleShim).Type,
           let viewManager = manager as? RNViewManager {
            let shim = shimType.init()
            viewManager.paymentMethodModule.attach(to: shim)
            return shim
        }
        return nil
    }
}

internal class RNViewManagerDelegate: RNFactoryDelegate {

    /// The JS bundle this manager's bridge should load (`hyperswitch` for the main
    /// payment SDK; payment-method session hosts pass their dedicated bundle name).
    /// This is the *output asset filename* (`hyperswitch-payment-methods.bundle`), not
    /// the Metro entry-module path — see `jsMainModuleName` for that.
    internal var bundleName = RNViewManagerDelegate.defaultBundleName

    /// The Metro entry-module path for this bundle (its entry file's name, no
    /// extension — `index` for `index.js`, `payment-methods` for `payment-methods.js`).
    /// Only used in "LocalHosted" (Metro dev server) mode; the packaged-bundle cases
    /// below key off `bundleName` (the asset filename) instead, which is unrelated.
    internal var jsMainModuleName = "index"

    internal static let defaultBundleName = "hyperswitch"

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    override func bundleURL() -> URL? {
        switch Helper.getInfoPlist("HyperswitchSource") {
        case "LocalHosted":
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: jsMainModuleName)
        case "LocalBundle":
            return bundleURL(for: bundleName, in: Bundle.main)
                ?? bundleURL(for: RNViewManagerDelegate.defaultBundleName, in: Bundle.main)
        default:
            #if canImport(HyperOTA)
            if bundleName == RNViewManagerDelegate.defaultBundleName {
                return OTAServices.shared.getBundleURL()
            }
            #endif
            return bundleURL(for: bundleName, in: Bundle(for: RNViewManager.self))
                ?? bundleURL(for: RNViewManagerDelegate.defaultBundleName, in: Bundle(for: RNViewManager.self))
        }
    }

    private func bundleURL(for name: String, in bundle: Bundle) -> URL? {
        return bundle.url(forResource: name, withExtension: "bundle")
    }
}

internal class RNViewManager: NSObject, ReactHostManager {

    internal let hyperModule = HyperModuleImpl()
    internal let headlessModule = HyperHeadlessImpl()
    /// Dedicated to payment-method session hosts only — never attached on the shared main-SDK host.
    internal let paymentMethodModule = PaymentMethodModuleImpl()
    internal var responseHandler: RNResponseHandler?
    internal private(set) var rootView: UIView?

    private let delegate: RNViewManagerDelegate

    internal lazy var factory: RCTReactNativeFactory = {
        RCTReactNativeFactory(delegate: self.delegate)
    }()

    /// Creates a manager whose React host loads the given JS bundle.
    /// Defaults to the main `hyperswitch` bundle; payment-method session hosts pass
    /// their dedicated `hyperswitch-payment-methods` bundle (and its Metro entry-module
    /// name, `payment-methods`) so each session runs on a fully separate JS runtime.
    internal init(
        bundleName: String = RNViewManagerDelegate.defaultBundleName,
        jsMainModuleName: String = "index"
    ) {
        let delegate = RNViewManagerDelegate()
        delegate.bundleName = bundleName
        delegate.jsMainModuleName = jsMainModuleName
        self.delegate = delegate
        super.init()
        self.delegate.dependencyProvider = RCTAppDependencyProvider()
        self.delegate.manager = self
        self.hyperModule.host = self
    }

    internal func presentedViewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        let rootView = factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
        self.rootView = rootView
        return rootView
    }

    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        return factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
    }

    internal func awaitReady() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                if self.hyperModule.isAttached {
                    continuation.resume()
                } else {
                    self.hyperModule.onAttached = { continuation.resume() }
                }
            }
        }
    }
}
