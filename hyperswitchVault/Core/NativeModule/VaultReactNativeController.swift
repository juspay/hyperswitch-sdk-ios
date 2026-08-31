//
//  VaultReactNativeController.swift
//  HyperswitchVault
//
//  Single shared React Native runtime used by every vault field surface.
//

import Foundation
import React
import React_RCTAppDelegate
#if canImport(ReactAppDependencyProvider)
import ReactAppDependencyProvider
#endif

internal class VaultReactDelegate: RCTDefaultReactNativeFactoryDelegate {

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    override func bundleURL() -> URL? {
        // `hyperswitch-vault.bundle` is shipped as a resource of the
        // HyperswitchVault framework/pod (see ios/hyperswitch-vault-sdk-ios.podspec).
        return Bundle(for: VaultReactNativeController.self)
            .url(forResource: "hyperswitch-vault", withExtension: "bundle")
    }
}

internal final class VaultReactNativeController {

    static let shared = VaultReactNativeController()

    internal let moduleName = "hs-vault"

    /// Event name for tokenise broadcasts; mirrors src/vault/registry.js.
    static let tokeniseEventName = "hsVaultTokenise"

    private let delegate: VaultReactDelegate

    internal lazy var factory: RCTReactNativeFactory = {
        RCTReactNativeFactory(delegate: delegate)
    }()

    private init() {
        delegate = VaultReactDelegate()
        #if canImport(ReactAppDependencyProvider)
        delegate.dependencyProvider = RCTAppDependencyProvider()
        #endif
    }

    /// Creates the surface (root view) of one vault field.
    internal func rootView(initialProperties: [String: Any]?) -> UIView {
        return factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
    }

    /// Broadcasts an event to every vault JS surface on this runtime.
    internal func emitDeviceEvent(name: String, body: Any? = nil) {
        factory.bridge?.eventDispatcher().sendDeviceEvent(withName: name, body: body)
    }
}

internal extension UIView {
    /// Root tag of the React surface hosted by this view, if any.
    var surfaceRootTag: NSNumber? {
        guard let rootView = self as? RCTSurfaceHostingProxyRootView else { return nil }
        return NSNumber(value: rootView.surface.rootTag)
    }
}
