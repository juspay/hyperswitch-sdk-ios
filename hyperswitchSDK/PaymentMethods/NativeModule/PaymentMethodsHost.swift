//
//  PaymentMethodsHost.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/09/26.
//

import Foundation
import React
import ReactAppDependencyProvider
import React_RCTAppDelegate

internal final class PaymentMethodsHostDelegate: RCTDefaultReactNativeFactoryDelegate {

    internal weak var host: PaymentMethodsHost?

    @objc(getModuleInstanceFromClass:)
    internal func getModuleInstanceFromClass(_ moduleClass: AnyClass) -> AnyObject? {
        guard let host = host else { return nil }
        if let shimType = moduleClass as? (NSObject & PaymentMethodsModuleShim).Type {
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
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: PaymentMethodsHost.entryFile)
        case "LocalBundle":
            return Bundle.main.url(forResource: PaymentMethodsHost.bundleName, withExtension: "bundle")
        default:
            return Bundle(for: PaymentMethodsHost.self).url(forResource: PaymentMethodsHost.bundleName, withExtension: "bundle")
        }
    }
}

/// The Payment Methods SDK's React host. A separate realm from the payments host: its own
/// bundle, its own native module, and none of the payments modules. Every form and every
/// field is one React root on it, told apart by root tag.
internal final class PaymentMethodsHost: NSObject, SurfaceHost {

    internal static let entryFile = "index.payment-methods"
    internal static let bundleName = "hyperswitch-payment-methods"

    /// Created on first use and kept for the life of the process.
    internal static let shared = PaymentMethodsHost()

    internal let module = PaymentMethodsModuleImpl()

    private let delegate: PaymentMethodsHostDelegate

    /// Evaluates the bundle's runtime chunk before the entry and tells the JS side where
    /// on-demand chunks live (see HyperReactNativeFactory.h).
    internal lazy var factory: RCTReactNativeFactory = {
        HyperReactNativeFactory(delegate: self.delegate, resourceDirectory: Self.resourceDirectory)
    }()

    /// Where the SDK's bundles and chunk files are packaged.
    private static let resourceDirectory = Bundle(for: PaymentMethodsHost.self).resourcePath

    /// Why this host cannot start: JavaScript it needs is missing from the app. Checked
    /// before React Native sees the bundle, whose fatal error for a missing one ends the
    /// app; the SDK reports SDK_INIT_FAILED instead. Main thread.
    internal lazy var initFailure: NSError? = {
        guard let missing = HyperReactNativeFactory.missingFiles(
            bundleURL: delegate.bundleURL(),
            resourceDirectory: Self.resourceDirectory
        ) else { return nil }
        return NSError.hyperswitch(
            "SDK_INIT_FAILED",
            "Hyperswitch SDK failed to initialise (payment methods): missing JavaScript: \(missing)"
        )
    }()


    private override init() {
        self.delegate = PaymentMethodsHostDelegate()
        super.init()
        self.delegate.dependencyProvider = RCTAppDependencyProvider()
        self.delegate.host = self
    }

    /// Boots the host, and with it the bundle, ahead of the first form. Idempotent.
    internal func warmUp() {
        DispatchQueue.main.async {
            guard self.initFailure == nil else { return }
            self.factory.rootViewFactory.initializeReactHost(
                launchOptions: nil,
                bundleConfiguration: RCTBundleConfiguration.default(),
                devMenuConfiguration: RCTDevMenuConfiguration.default()
            )
        }
    }

    /// Creates one React root. [owner] is the native object every JS call carrying this
    /// root's tag resolves to; nothing else records which form or field a root belongs to.
    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?, owner: AnyObject) -> UIView {
        // No React root when the host cannot start; CardForm reports it through onError.
        guard initFailure == nil else { return UIView() }
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
