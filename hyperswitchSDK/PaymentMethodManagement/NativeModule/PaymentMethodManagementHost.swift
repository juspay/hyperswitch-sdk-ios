//
//  PaymentMethodManagementHost.swift
//  Hyperswitch
//
//  The Payment Methods Management React host.
//

import Foundation
import React
import ReactAppDependencyProvider
import React_RCTAppDelegate

internal final class PaymentMethodManagementHostDelegate: RCTDefaultReactNativeFactoryDelegate {

    internal weak var host: PaymentMethodManagementHost?

    @objc(getModuleInstanceFromClass:)
    internal func getModuleInstanceFromClass(_ moduleClass: AnyClass) -> AnyObject? {
        guard let host = host else { return nil }
        if let shimType = moduleClass as? (NSObject & PaymentMethodManagementModuleShim).Type {
            let shim = shimType.init()
            host.module.attach(to: shim)
            return shim
        }
        return nil
    }

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    override func bundleURL() -> URL? {
        switch Helper.getInfoPlist("HyperswitchSource") {
        case "LocalHosted":
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: PaymentMethodManagementHost.entryFile)
        case "LocalBundle":
            return Bundle.main.url(forResource: PaymentMethodManagementHost.bundleName, withExtension: "bundle")
        default:
            return Bundle(for: PaymentMethodManagementHost.self).url(forResource: PaymentMethodManagementHost.bundleName, withExtension: "bundle")
        }
    }
}

/// The Payment Method Management host: a separate realm from the payments host — its own
/// bundle, its own native module, and none of the payments modules. Every PMM sheet or
/// widget is one React root on it, told apart by root tag.
internal final class PaymentMethodManagementHost: NSObject {

    internal static let entryFile = "index.payment-method-management"
    internal static let bundleName = "hyperswitch-payment-method-management"

    /// Created on first use and kept for the life of the process.
    internal static let shared = PaymentMethodManagementHost()

    internal let module = PaymentMethodManagementModuleImpl()

    private let delegate: PaymentMethodManagementHostDelegate

    internal lazy var factory: RCTReactNativeFactory = {
        RCTReactNativeFactory(delegate: self.delegate)
    }()

    private override init() {
        self.delegate = PaymentMethodManagementHostDelegate()
        super.init()
        self.delegate.dependencyProvider = RCTAppDependencyProvider()
        self.delegate.host = self
    }

    /// Boots the host, and with it the bundle, ahead of the first PMM surface. Idempotent.
    internal func warmUp() {
        DispatchQueue.main.async {
            self.factory.rootViewFactory.initializeReactHost(
                launchOptions: nil,
                bundleConfiguration: RCTBundleConfiguration.default(),
                devMenuConfiguration: RCTDevMenuConfiguration.default()
            )
        }
    }

    /// Creates one React root. [owner] is the native object every JS call carrying this
    /// root's tag resolves to; nothing else records which sheet or widget a root belongs to.
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
}
