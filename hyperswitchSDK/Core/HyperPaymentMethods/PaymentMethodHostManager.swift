//
//  PaymentMethodHostManager.swift
//  hyperswitch
//
//  The payment-method session SDK's own React host — fully separate from the main
//  SDK's `RNViewManager`: own `RCTReactNativeFactory` → own `RCTHost` → own JS
//  runtime loading the dedicated `hyperswitch-payment-methods` bundle.
//

import Foundation
import React
import ReactAppDependencyProvider
import React_RCTAppDelegate

/// Factory delegate for the payment-method session host. Loads this SDK's dedicated
/// `hyperswitch-payment-methods` JS bundle and serves only `PaymentMethodModule`
/// (via `PaymentMethodModuleShim`) — the main SDK's modules are never created here.
internal final class PaymentMethodHostDelegate: RCTDefaultReactNativeFactoryDelegate {

    internal weak var manager: PaymentMethodHostManager?

    /// Output asset filename of this SDK's JS bundle, shipped in `Core/Resources`.
    internal static let bundleName = "hyperswitch-payment-methods"

    /// The Metro entry-module path for this bundle (its entry file's name, no
    /// extension — `payment-methods` for `payment-methods.js`). Only used in
    /// "LocalHosted" (Metro dev server) mode; the packaged-bundle cases below key
    /// off `bundleName` (the asset filename) instead, which is unrelated.
    internal static let jsMainModuleName = "payment-methods"

    @objc(getModuleInstanceFromClass:)
    internal func getModuleInstanceFromClass(_ moduleClass: AnyClass) -> AnyObject? {
        guard let manager = manager,
              let shimType = moduleClass as? (NSObject & PaymentMethodModuleShim).Type else {
            return nil
        }
        let shim = shimType.init()
        manager.paymentMethodModule.attach(to: shim)
        return shim
    }

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    override func bundleURL() -> URL? {
        switch PMContext.infoPlist("HyperswitchSource") {
        case "LocalHosted":
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: Self.jsMainModuleName)
        case "LocalBundle":
            return bundleURL(for: Self.bundleName, in: Bundle.main)
        default:
            return bundleURL(for: Self.bundleName, in: Bundle.main)
                ?? bundleURL(for: Self.bundleName, in: Bundle(for: PaymentMethodHostManager.self))
        }
    }

    private func bundleURL(for name: String, in bundle: Bundle) -> URL? {
        return bundle.url(forResource: name, withExtension: "bundle")
    }
}

/// The payment-method session SDK's own React host. A fresh instance is created per
/// `PaymentMethodSession` — `RNViewManager.shared` (the main SDK's host) is never
/// used, so every payment-method session runs on its own isolated JS runtime.
internal final class PaymentMethodHostManager: NSObject {

    /// The single TurboModule this host serves — payment-method events never touch
    /// the main SDK's event bus.
    internal let paymentMethodModule = PaymentMethodModuleImpl()

    internal private(set) var rootView: UIView?

    private let delegate = PaymentMethodHostDelegate()

    internal lazy var factory: RCTReactNativeFactory = {
        RCTReactNativeFactory(delegate: self.delegate)
    }()

    internal override init() {
        super.init()
        self.delegate.dependencyProvider = RCTAppDependencyProvider()
        self.delegate.manager = self
    }

    /// Boots the host, and with it the bundle, ahead of the first surface so
    /// `initPaymentMethodSession` does not wait for JS evaluation. Idempotent.
    internal func warmUp() {
        DispatchQueue.main.async {
            self.factory.rootViewFactory.initializeReactHost(
                launchOptions: nil,
                bundleConfiguration: RCTBundleConfiguration.default(),
                devMenuConfiguration: RCTDevMenuConfiguration.default()
            )
        }
    }

    /// Creates one React root on this host (card-form controller surface or an
    /// input widget's internal view).
    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        return factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
    }

    /// Single-root flows on this host: the root created here is the one kept for
    /// the life of the session.
    internal func presentedViewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        let rootView = viewForModule(moduleName, initialProperties: initialProperties)
        self.rootView = rootView
        return rootView
    }
}
